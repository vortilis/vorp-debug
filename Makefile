REGISTRY     := ghcr.io/vortilis
DEBUG_IMAGE  := $(REGISTRY)/vorp-debug
SHELL_IMAGE  := $(REGISTRY)/vorp-shell
VERSION      := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
KUBE_VERSION := $(shell sed -n 's/.*KUBE_VERSION="v\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' Dockerfile)
CRICTL_VERSION := $(shell sed -n 's/.*CRICTL_VERSION="v\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' Dockerfile)
PLATFORMS    := linux/amd64,linux/arm64

.PHONY: help build build-shell build-multi push test test-shell run run-shell clean version bump

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the debug image for current platform
	docker buildx build --load --target debug -t $(DEBUG_IMAGE):$(VERSION) -t $(DEBUG_IMAGE):local .

build-shell: ## Build the shell image for current platform
	docker buildx build --load --target shell -t $(SHELL_IMAGE):$(VERSION) -t $(SHELL_IMAGE):local .

build-multi: ## Build both images multi-platform (no push)
	docker buildx build --platform $(PLATFORMS) --target debug -t $(DEBUG_IMAGE):$(VERSION) .
	docker buildx build --platform $(PLATFORMS) --target shell -t $(SHELL_IMAGE):$(VERSION) .

push: ## Build both images multi-platform and push to GHCR
	docker buildx build --platform $(PLATFORMS) --target debug --push \
		-t $(DEBUG_IMAGE):$(VERSION) \
		-t $(DEBUG_IMAGE):latest \
		.
	docker buildx build --platform $(PLATFORMS) --target shell --push \
		-t $(SHELL_IMAGE):$(VERSION) \
		-t $(SHELL_IMAGE):latest \
		.

test: build ## Build the debug image and run smoke tests
	@echo "Running smoke tests..."
	@docker run --rm $(DEBUG_IMAGE):local sh -c '\
		set -e; \
		for tool in dig curl tcpdump crictl kubectl jq yq strace ip htop ss ncat openssl socat ethtool ipvsadm iostat vim tmux screen less file tree watch; do \
			printf "  %-12s" "$$tool"; \
			which "$$tool" >/dev/null && echo "OK" || { echo "MISSING"; exit 1; }; \
		done; \
		echo ""; \
		echo "Versions:"; \
		crictl --version; \
		kubectl version --client --short 2>/dev/null || kubectl version --client; \
		echo ""; \
		echo "All smoke tests passed!"'

test-shell: build-shell ## Build the shell image and run smoke tests (as its non-root user)
	@echo "Running smoke tests..."
	@docker run --rm $(SHELL_IMAGE):local sh -c '\
		set -e; \
		[ "$$(id -u)" = 65532 ] || { echo "runs as uid $$(id -u), expected 65532"; exit 1; }; \
		for tool in dig curl wget ping traceroute ip ss ncat telnet openssl socat kubectl jq yq vim tmux less ps; do \
			printf "  %-12s" "$$tool"; \
			which "$$tool" >/dev/null && echo "OK" || { echo "MISSING"; exit 1; }; \
		done; \
		for tool in tcpdump crictl strace bpftool iptables; do \
			printf "  %-12s" "$$tool"; \
			which "$$tool" >/dev/null && { echo "UNEXPECTED (debug-only tool)"; exit 1; } || echo "absent"; \
		done; \
		mkdir -p "$$HOME/.kube/cache" && rm -rf "$$HOME/.kube"; \
		echo ""; \
		echo "Versions:"; \
		kubectl version --client; \
		echo ""; \
		echo "All smoke tests passed!"'

run: build ## Run interactive debug container
	docker run --rm -it $(DEBUG_IMAGE):local

run-shell: build-shell ## Run interactive shell container
	docker run --rm -it $(SHELL_IMAGE):local

clean: ## Remove local images
	-docker rmi $(DEBUG_IMAGE):local $(DEBUG_IMAGE):$(VERSION) $(SHELL_IMAGE):local $(SHELL_IMAGE):$(VERSION) 2>/dev/null

version: ## Show current version
	@echo "Image:  $(VERSION)"
	@echo "Kube:   v$(KUBE_VERSION)"
	@echo "crictl: v$(CRICTL_VERSION)"

bump: ## Bump kube version: make bump V=1.32.0
ifndef V
	@./script/bump
else
	./script/bump $(V)
endif
