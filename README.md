# vorp-debug

Kubernetes debug toolkit, published as two images. Multi-platform: `linux/amd64` and `linux/arm64`.

| Image | Runs as | For |
|---|---|---|
| `ghcr.io/vortilis/vorp-debug` | root | Node debugging: a privileged container with 30+ networking, tracing, and system tools |
| `ghcr.io/vortilis/vorp-shell` | uid 65532 | A shell inside the cluster: `kubectl` and network tools, no host access. Works in namespaces that enforce the `restricted` Pod Security Standard |

## Included Tools

### vorp-debug

| Category | Tools |
|---|---|
| **DNS & Networking** | `curl`, `wget`, `dig`, `nslookup`, `ping`, `traceroute`, `mtr`, `httping`, `ifconfig`, `netstat`, `ip`, `ss`, `ncat`, `telnet`, `openssl`, `socat`, `ethtool` |
| **Packet Capture** | `tcpdump`, `termshark`, `dsniff` |
| **Process & System** | `htop`, `atop`, `dstat`, `strace`, `lsof`, `pstree`, `killall`, `iostat`, `sar` |
| **Firewall & IPVS** | `iptables`, `conntrack`, `ipvsadm` |
| **BPF & Tracing** | `bpftool`, `llvm` |
| **Kubernetes** | `kubectl`, `crictl` |
| **Utilities** | `vim`, `tmux`, `screen`, `jq`, `yq`, `less`, `file`, `tree`, `watch`, `man` |

### vorp-shell

| Category | Tools |
|---|---|
| **DNS & Networking** | `curl`, `wget`, `dig`, `nslookup`, `ping`, `traceroute`, `ip`, `ss`, `ncat`, `telnet`, `openssl`, `socat` |
| **Kubernetes** | `kubectl` (with bash completion) |
| **Utilities** | `vim`, `tmux`, `jq`, `yq`, `less`, `ps`, `top` |

Tools that need root or capabilities (packet capture, tracing, firewall, `crictl`) are left out. `HOME` is `/tmp`, so `kubectl` has a writable place for its discovery cache. Inside a pod, `kubectl` uses the pod's ServiceAccount.

`ping` uses unprivileged ICMP sockets, which the kernel allows only for the groups in `net.ipv4.ping_group_range`. Kubernetes treats that sysctl as safe, so a pod can set it:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: shell
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
    sysctls:
      - name: net.ipv4.ping_group_range
        value: "0 2147483647"
  containers:
    - name: shell
      image: ghcr.io/vortilis/vorp-shell:1.35.9
      command: ["sleep", "infinity"]
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
```

## Versioning

Image versions follow `kubectl`. For example, image `1.35.9` ships with `kubectl v1.35.9`. `crictl` (in `vorp-debug` only) does not publish a release for every Kubernetes patch, so it takes the newest release of the same minor (`crictl v1.35.0` in image `1.35.9`).

A release tag `v1.35.9` produces:

```
ghcr.io/vortilis/vorp-debug:1.35.9
ghcr.io/vortilis/vorp-debug:1.35
ghcr.io/vortilis/vorp-debug:latest
ghcr.io/vortilis/vorp-shell:1.35.9
ghcr.io/vortilis/vorp-shell:1.35
ghcr.io/vortilis/vorp-shell:latest
```

To bump to a new Kubernetes version:

```bash
make bump V=1.36.0   # validates that kubectl and crictl releases exist, updates Dockerfile
```

## Local Development

Both images are built from one `Dockerfile`: `--target debug` (the default) and `--target shell`.

```bash
make help        # show all targets
make build       # build vorp-debug for current platform
make build-shell # build vorp-shell for current platform
make test        # build + smoke test vorp-debug
make test-shell  # build + smoke test vorp-shell (as its non-root user)
make run         # interactive vorp-debug shell
make run-shell   # interactive vorp-shell shell
make build-multi # build both for amd64 + arm64
make push        # build both multi-platform + push to GHCR
```

## Releasing

```bash
git tag v1.35.9
git push origin v1.35.9
```

GitHub Actions will automatically build multi-platform images for both and push them to GHCR.

## License

MIT
