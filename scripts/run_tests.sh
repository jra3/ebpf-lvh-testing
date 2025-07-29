#!/bin/bash
set -e

echo "=== Running eBPF Tests ==="

# Check environment
if [[ -d /host ]]; then
    echo "Running inside LVH VM"
    cd /host
fi

# Install dependencies
echo "Installing test dependencies..."
apt-get update > /dev/null 2>&1
apt-get install -y bpftool libbpf-dev make clang > /dev/null 2>&1

# Build eBPF programs
echo "Building eBPF programs..."
make -C src/bpf clean all

# Load and test programs
echo "Loading eBPF programs..."
bpftool prog load src/bpf/simple_kprobe.o /sys/fs/bpf/test_kprobe

# Verify program loaded
echo "Verifying programs..."
bpftool prog show name trace_open

# Check for errors
if dmesg | grep -i "verification failed" > /dev/null; then
    echo "ERROR: BPF verification failed"
    exit 1
fi

echo "All tests passed!"

# Cleanup
rm -f /sys/fs/bpf/test_kprobe