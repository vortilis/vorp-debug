FROM debian:12-slim

ARG KUBE_VERSION="v1.35.0"
ARG YQ_VERSION="v4.44.6"
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

RUN curl -fsSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${KUBE_VERSION}/crictl-${KUBE_VERSION}-linux-${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin \
    && printf "runtime-endpoint: unix:///run/containerd/containerd.sock\nimage-endpoint: unix:///run/containerd/containerd.sock\n" > /etc/crictl.yaml

RUN curl -fsSL "https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/${TARGETARCH}/kubectl" \
    -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${TARGETARCH}" \
    -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

CMD [ "/bin/bash" ]
