# Two images from one file, picked with --target:
#   debug — node debugging toolkit, runs as root (default: the last stage)
#   shell — kubectl and network tools as a non-root user, for namespaces
#           that enforce the "restricted" Pod Security Standard
#
# The image version is the kubectl version. crictl publishes only a few
# releases per minor (often just X.Y.0), so it has its own version within
# the same minor line; script/bump keeps the two in step.

ARG KUBE_VERSION="v1.35.9"
ARG CRICTL_VERSION="v1.35.0"
ARG YQ_VERSION="v4.44.6"

# ── base: shared by both images ──────────────────────────────────────────
FROM debian:12-slim AS base

LABEL org.opencontainers.image.source="https://github.com/vortilis/vorp-debug"

ARG KUBE_VERSION
ARG YQ_VERSION
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH}" \
    -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# ── shell: non-root, no host access ──────────────────────────────────────
# Only tools that work without root or capabilities: no packet capture,
# tracing, firewall or container runtime tools. ping needs the pod sysctl
# net.ipv4.ping_group_range, since raw sockets are not available.
FROM base AS shell

RUN apt-get update && apt-get install -y --no-install-recommends \
    # DNS & networking
    dnsutils \
    iputils-ping \
    traceroute \
    iproute2 \
    ncat \
    telnet \
    openssl \
    socat \
    wget \
    # utilities
    bash-completion \
    jq \
    less \
    procps \
    tmux \
    vim \
    && rm -rf /var/lib/apt/lists/* \
    && kubectl completion bash > /usr/share/bash-completion/completions/kubectl \
    # kubectl exec starts a non-login shell without a ~/.bashrc
    && echo '. /usr/share/bash-completion/bash_completion' >> /etc/bash.bashrc \
    # Debian ships ping with cap_net_raw+ep, and the kernel refuses to exec a
    # binary whose file capabilities it cannot grant (capabilities dropped).
    # Without them ping uses unprivileged ICMP sockets instead.
    && setcap -r /usr/bin/ping \
    && groupadd --gid 65532 vorp \
    && useradd --uid 65532 --gid 65532 --no-create-home --home-dir /tmp --shell /bin/bash vorp

# Numeric, so the kubelet can verify runAsNonRoot without a runAsUser in the pod.
USER 65532:65532
# kubectl caches API discovery under $HOME/.kube; /tmp is writable for everyone.
ENV HOME=/tmp
WORKDIR /tmp

CMD [ "/bin/bash" ]

# ── debug: privileged node toolkit (default target) ──────────────────────
FROM base AS debug

ARG CRICTL_VERSION
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    wget \
    software-properties-common \
    gnupg \
    # DNS & networking
    dnsutils \
    iputils-ping \
    traceroute \
    mtr-tiny \
    httping \
    net-tools \
    iproute2 \
    ncat \
    telnet \
    openssl \
    socat \
    ethtool \
    # packet capture
    tcpdump \
    termshark \
    dsniff \
    # process & system monitoring
    htop \
    atop \
    dstat \
    strace \
    lsof \
    psmisc \
    sysstat \
    # firewall & conntrack & IPVS
    iptables \
    conntrack \
    ipvsadm \
    # BPF tools
    bpftool \
    llvm \
    # editors & utilities
    vim \
    tmux \
    screen \
    jq \
    less \
    file \
    tree \
    man-db \
    watch \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin \
    && printf "runtime-endpoint: unix:///run/containerd/containerd.sock\nimage-endpoint: unix:///run/containerd/containerd.sock\n" > /etc/crictl.yaml

CMD [ "/bin/bash" ]
