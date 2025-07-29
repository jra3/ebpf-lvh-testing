# LVH (Little VM Helper) Usage Guide

## What is LVH?

LVH (little-vm-helper) is a VM management tool by Cilium, designed for kernel development and testing, particularly for BPF/eBPF features. It's NOT meant for production VMs.

## Installation

```bash
# Install via Go
go install github.com/cilium/little-vm-helper/cmd/lvh@latest

# Install dependencies (Debian/Ubuntu)
sudo apt-get install qemu-kvm mmdebstrap debian-archive-keyring libguestfs-tools
```

## Basic Usage

### 1. **Pull Pre-built Kernels**
```bash
lvh kernels pull 6.6-main
```

### 2. **Run a VM**
```bash
# Basic run
lvh run --image base.qcow2 --kernel ./kernels/bzImage

# With custom options
lvh run --image kind_bpf-next.qcow2 \
  --host-mount $(pwd) \
  --kernel ./bpf-next/arch/x86_64/boot/bzImage \
  --daemonize -p 2222:22 --cpu=3 --mem=6G

# On macOS (no KVM)
lvh run --image base.qcow2 --qemu-disable-kvm
```

### 3. **Build Custom Kernels**
```bash
# Initialize kernel directory
lvh kernels --dir _data init

# Add kernel source
lvh kernels --dir _data add bpf-next git://git.kernel.org/pub/scm/linux/kernel/git/bpf/bpf-next.git --fetch

# Build kernel
lvh kernels --dir _data build bpf-next
```

### 4. **Build VM Images**
```bash
# Generate example config
lvh images example-config > images.json

# Build images
lvh images build --dir _data
```

## Key Features

- **Fast VM creation** with minimal storage overhead
- **Kernel management** - build, download, and manage multiple kernels
- **Cross-architecture support** (--arch=arm64 or --arch=amd64)
- **Host mounts** for sharing files between host and VM
- **GitHub Action support** for CI/CD pipelines

## Common Use Cases

1. **BPF/eBPF Development**: Test BPF programs across different kernel versions
2. **Kernel Testing**: Quickly boot VMs with custom kernels
3. **CI/CD**: Automated testing in GitHub Actions
4. **Cilium/Tetragon Development**: Used extensively in these projects

The tool is particularly useful for developers working on kernel-level features who need to quickly test across different kernel versions without the overhead of full VM management solutions.