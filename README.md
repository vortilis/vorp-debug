# vorp-debug

Kubernetes node debug toolkit. A privileged container with 30+ networking, tracing, and system debugging tools pre-installed. Multi-platform: `linux/amd64` and `linux/arm64`.

## Included Tools

| Category | Tools |
|---|---|
| **DNS & Networking** | `curl`, `wget`, `dig`, `nslookup`, `ping`, `traceroute`, `mtr`, `httping`, `ifconfig`, `netstat`, `ip`, `ss`, `ncat`, `telnet`, `openssl`, `socat`, `ethtool` |
| **Packet Capture** | `tcpdump`, `termshark`, `dsniff` |
| **Process & System** | `htop`, `atop`, `dstat`, `strace`, `lsof`, `pstree`, `killall`, `iostat`, `sar` |
| **Firewall & IPVS** | `iptables`, `conntrack`, `ipvsadm` |
| **BPF & Tracing** | `bpftool`, `llvm` |
| **Kubernetes** | `kubectl`, `crictl` |
| **Utilities** | `vim`, `tmux`, `screen`, `jq`, `yq`, `less`, `file`, `tree`, `watch`, `man` |

## Versioning

Image versions are aligned with `kubectl`/`crictl` versions. For example, image `v1.35.0` ships with `kubectl v1.35.0` and `crictl v1.35.0`.

A release tag `v1.35.0` produces:

```
ghcr.io/vortilis/vorp-debug:1.35.0
ghcr.io/vortilis/vorp-debug:1.35
ghcr.io/vortilis/vorp-debug:latest
```

To bump to a new Kubernetes version:

```bash
make bump V=1.36.0   # validates that crictl/kubectl releases exist, updates Dockerfile
```

## Local Development

```bash
make help        # show all targets
make build       # build for current platform
make test        # build + smoke test
make run         # interactive shell
make build-multi # build for amd64 + arm64
make push        # build multi-platform + push to GHCR
```

## Releasing

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically build multi-platform images and push to GHCR.

## License

MIT
