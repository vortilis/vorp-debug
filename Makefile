IMAGE_NAME  := ghcr.io/vortilis/vorp-debug
VERSION     := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
KUBE_VERSION := $(shell sed -n 's/.*KUBE_VERSION="v\([0-9]*\.[0-9]*\.[0-9]*\)".*/\1/p' Dockerfile)
PLATFORMS   := linux/amd64,linux/arm64

.PHONY: help build build-multi push test run clean version bump

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build image for current platform
	docker buildx build --load -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):local .

build-multi: ## Build multi-platform image (no push)
	docker buildx build --platform $(PLATFORMS) -t $(IMAGE_NAME):$(VERSION) .

push: ## Build multi-platform and push to GHCR
	docker buildx build --platform $(PLATFORMS) --push \
		-t $(IMAGE_NAME):$(VERSION) \
		-t $(IMAGE_NAME):latest \
		.

test: build ## Build and run smoke tests
	@echo "Running smoke tests..."
	@docker run --rm $(IMAGE_NAME):local sh -c '\
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

run: build ## Run interactive debug container
	docker run --rm -it $(IMAGE_NAME):local

clean: ## Remove local images
	-docker rmi $(IMAGE_NAME):local $(IMAGE_NAME):$(VERSION) 2>/dev/null

version: ## Show current version
	@echo "Image: $(VERSION)"
	@echo "Kube:  v$(KUBE_VERSION)"

bump: ## Bump kube version: make bump V=1.32.0
ifndef V
	@./script/bump
else
	./script/bump $(V)
endif
