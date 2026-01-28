# SPDX-FileCopyrightText: 2026 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: AGPL-3.0-only

# Makefile for building service-discover-base package using YAP
#
# Usage:
#   make build TARGET=ubuntu-jammy           # Build package for Ubuntu 22.04
#   make build TARGET=rocky-9                # Build package for Rocky Linux 9
#   make clean                               # Clean build artifacts
#
# Supported targets:
#   ubuntu-jammy, ubuntu-noble, rocky-8, rocky-9

# Configuration
YAP_IMAGE_PREFIX ?= docker.io/m0rf30/yap
YAP_VERSION ?= 1.47
CONTAINER_RUNTIME ?= $(shell command -v podman >/dev/null 2>&1 && echo podman || echo docker)

# Build directories
OUTPUT_DIR ?= artifacts

# CCache directory for build caching
CCACHE_DIR ?= $(CURDIR)/.ccache

# Default target (can be overridden)
TARGET ?= ubuntu-jammy

# Container image name (format: docker.io/m0rf30/yap-<target>:<version>)
YAP_IMAGE = $(YAP_IMAGE_PREFIX)-$(TARGET):$(YAP_VERSION)

# Container name
CONTAINER_NAME ?= yap-$(TARGET)-service-discover

# Container options
CONTAINER_OPTS = --rm -ti \
	--name $(CONTAINER_NAME) \
	--entrypoint bash \
	-v $(CURDIR):/project \
	-v $(CURDIR)/$(OUTPUT_DIR):/artifacts \
	-v $(CCACHE_DIR):/root/.ccache \
	-e CCACHE_DIR=/root/.ccache

.PHONY: all build clean list-targets help pull

# Default target
all: help

## help: Show this help message
help:
	@echo "Service Discover Base - Build System"
	@echo ""
	@echo "This Makefile builds the service-discover-base package using YAP"
	@echo "(Yet Another Packager) in Podman/Docker containers."
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [TARGET=<distro>] [OPTIONS]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
	@echo ""
	@echo "Options:"
	@echo "  TARGET             Distribution target (default: $(TARGET))"
	@echo "  YAP_IMAGE_PREFIX   YAP image prefix (default: $(YAP_IMAGE_PREFIX))"
	@echo "  YAP_VERSION        YAP image version (default: $(YAP_VERSION))"
	@echo "  CONTAINER_RUNTIME  Container runtime (default: podman, fallback: docker)"
	@echo "  CONTAINER_NAME     Container name (default: $(CONTAINER_NAME))"
	@echo "  OUTPUT_DIR         Output directory for packages (default: $(OUTPUT_DIR))"
	@echo "  CCACHE_DIR         CCache directory for build caching (default: $(CCACHE_DIR))"
	@echo ""
	@echo "Examples:"
	@echo "  make build TARGET=ubuntu-jammy"
	@echo "  make build TARGET=rocky-9"
	@echo "  make pull TARGET=ubuntu-noble"
	@echo ""

## build: Build the package for the specified TARGET
build:
	@echo "Building service-discover-base for $(TARGET)..."
	@mkdir -p $(OUTPUT_DIR) $(CCACHE_DIR)
	$(CONTAINER_RUNTIME) run $(CONTAINER_OPTS) $(YAP_IMAGE) -c "yap prepare $(TARGET) -g && yap build $(TARGET) /project/consul"

## pull: Pull the YAP container image for the specified TARGET
pull:
	@echo "Pulling YAP image for $(TARGET)..."
	$(CONTAINER_RUNTIME) pull $(YAP_IMAGE)

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(OUTPUT_DIR)
	rm -rf consul/artifacts

## list-targets: List supported distribution targets
list-targets:
	@echo "Supported distribution targets:"
	@echo ""
	@echo "  ubuntu-jammy    (Ubuntu 22.04 LTS)"
	@echo "  ubuntu-noble    (Ubuntu 24.04 LTS)"
	@echo "  rocky-8         (Rocky Linux 8)"
	@echo "  rocky-9         (Rocky Linux 9)"
	@echo ""
	@echo "Usage: make build TARGET=<target>"
