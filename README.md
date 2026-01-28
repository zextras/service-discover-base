# Service Discover Base

Service discovery binary for Carbonio, based on HashiCorp Consul. This package provides the core service discovery and configuration management infrastructure used by Carbonio components to communicate and coordinate within distributed deployments.

## Quick Start

### Prerequisites

- Docker or Podman installed
- Make

### Building Packages

```bash
# Build packages for Ubuntu 22.04
make build TARGET=ubuntu-jammy

# Build packages for Rocky Linux 9
make build TARGET=rocky-9

# Build packages for Ubuntu 24.04
make build TARGET=ubuntu-noble
```

### Supported Targets

- `ubuntu-jammy` - Ubuntu 22.04 LTS
- `ubuntu-noble` - Ubuntu 24.04 LTS
- `rocky-8` - Rocky Linux 8
- `rocky-9` - Rocky Linux 9

### Configuration

You can customize the build by setting environment variables:

```bash
# Use a specific container runtime
make build TARGET=ubuntu-jammy CONTAINER_RUNTIME=docker

# Use a different output directory
make build TARGET=rocky-9 OUTPUT_DIR=./my-packages
```

## Installation

This package is distributed as part of the [Carbonio platform](https://zextras.com/carbonio).

### Ubuntu (Jammy/Noble)

```bash
apt-get install service-discover-base
```

### Rocky Linux (8/9)

```bash
yum install service-discover-base
```

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for information on how to contribute to this project.

## License

This repository contains build configurations and packaging scripts licensed under the GNU Affero General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.
