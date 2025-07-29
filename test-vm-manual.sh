#!/bin/bash
# Manual VM testing with downloaded kernel images

set -e

echo "=== Manual VM Testing Setup ==="
echo ""

# Create directory for kernels if not exists
mkdir -p kernels

echo "To test with different kernels manually:"
echo ""
echo "1. Download kernel images:"
echo "   - Ubuntu mainline kernels: https://kernel.ubuntu.com/mainline/"
echo "   - Or use LVH to download: lvh kernels pull 5.15-main"
echo ""
echo "2. Use QEMU to boot with a simple rootfs:"
echo "   - Download Alpine or Debian minimal rootfs"
echo "   - Mount the compiled BPF programs"
echo ""
echo "3. Or use an existing VM/container platform:"
echo "   - Multipass: multipass launch --name bpf-test"
echo "   - Vagrant with different boxes"
echo "   - LXD with different kernels"
echo ""

# Quick test with chroot if you have debootstrap
if command -v debootstrap >/dev/null 2>&1; then
    echo "4. Quick test with chroot (same kernel, different userspace):"
    echo "   sudo debootstrap --variant=minbase stable /tmp/test-root"
    echo "   sudo cp -r src/bpf /tmp/test-root/tmp/"
    echo "   sudo chroot /tmp/test-root /bin/bash"
    echo "   # Inside chroot: apt-get update && apt-get install -y bpftool"
    echo "   # Then test BPF loading"
fi