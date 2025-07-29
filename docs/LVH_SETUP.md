# LVH (Little VM Helper) Setup Guide

## What is LVH?

LVH is a tool developed by the Cilium project for managing VMs specifically for kernel development and testing. It's designed to make it easy to test kernel features (especially BPF) across different kernel versions.

## Installation

### Prerequisites

- Go 1.21 or newer
- Linux host system
- QEMU/KVM (for running VMs)
- Sufficient disk space for VM images

### Installing LVH

```bash
# Install from source
go install github.com/cilium/little-vm-helper/cmd/lvh@latest

# Add to PATH
export PATH="$PATH:$(go env GOPATH)/bin"

# Verify installation
lvh --help
```

## Core Concepts

### 1. Kernels
LVH can download pre-built kernels or build them from source:

```bash
# List available pre-built kernels
lvh kernels catalog

# Pull a pre-built kernel
lvh kernels pull 6.1-main

# Build custom kernel
lvh kernels init --dir my-kernels
lvh kernels add --dir my-kernels bpf-next git://git.kernel.org/.../bpf-next.git
lvh kernels build --dir my-kernels bpf-next
```

### 2. VM Images
LVH uses qcow2 images that must be built locally:

```bash
# Generate example configuration
lvh images example-config > images.json

# Customize the configuration
cat images.json
[
  {
    "name": "base",
    "packages": [
      "systemd",
      "openssh-server",
      "iproute2",
      "bpftool",
      "make",
      "gcc",
      "clang"
    ]
  }
]

# Build the image
lvh images build --dir .
```

### 3. Running VMs

```bash
# Basic VM run
lvh run --image base.qcow2 --kernel path/to/bzImage

# With host directory mounted
lvh run --image base.qcow2 \
        --kernel path/to/bzImage \
        --host-mount $(pwd) \
        --daemonize \
        -p 2222:22

# Connect to VM
ssh -p 2222 root@localhost
```

## Common Use Cases

### Testing eBPF Programs

1. Build your eBPF programs on the host
2. Start VM with host mount
3. Load and test programs inside VM

```bash
# On host
make -C src/bpf

# Start VM
lvh run --image base.qcow2 \
        --kernel kernels/6.1-main/bzImage \
        --host-mount $(pwd)

# Inside VM
cd /host
bpftool prog load src/bpf/my_prog.o /sys/fs/bpf/test
bpftool prog show
```

### Multi-Kernel Testing

```bash
#!/bin/bash
KERNELS=("5.15-main" "6.1-main" "6.6-main")

for kernel in "${KERNELS[@]}"; do
    echo "Testing on kernel $kernel"
    lvh run --image base.qcow2 \
            --kernel kernels/$kernel/bzImage \
            --host-mount $(pwd) \
            --daemonize
    
    ssh -p 2222 root@localhost "/host/run_tests.sh"
    lvh stop
done
```

## Tips and Tricks

1. **Kernel Storage**: Kernels are stored in `~/.cache/lvh/kernels/` by default

2. **Image Building**: Keep images minimal for faster boot times

3. **Debugging**: Use `--serial` flag to see boot messages:
   ```bash
   lvh run --image base.qcow2 --kernel kernel.bzImage --serial
   ```

4. **Performance**: Use `--cpu` and `--mem` flags to allocate resources:
   ```bash
   lvh run --image base.qcow2 --kernel kernel.bzImage --cpu 4 --mem 4G
   ```

## Troubleshooting

### VM Won't Start
- Check QEMU is installed: `qemu-system-x86_64 --version`
- Verify image exists and is valid
- Check kernel path is correct

### Can't Connect via SSH
- Ensure VM has booted fully (wait 30-60 seconds)
- Check port forwarding: `-p 2222:22`
- Verify SSH service is in the image

### Build Failures
- Ensure all dependencies are installed
- Check disk space
- Review build logs for specific errors