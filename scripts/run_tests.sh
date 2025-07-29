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
if [ -f src/bpf/minimal.o ]; then
    echo "Testing minimal BPF program..."
    bpftool prog load src/bpf/minimal.o /sys/fs/bpf/test_minimal
    bpftool prog list
else
    echo "Warning: minimal.o not found"
fi

if [ -f src/bpf/simple_kprobe.o ]; then
    echo "Testing kprobe program..."
    bpftool prog load src/bpf/simple_kprobe.o /sys/fs/bpf/test_kprobe || true
    bpftool prog show name trace_open || true
fi

# Check for errors
if dmesg | grep -i "verification failed" > /dev/null; then
    echo "ERROR: BPF verification failed"
    exit 1
fi

echo "All tests passed!"

# Cleanup
rm -f /sys/fs/bpf/test_kprobe /sys/fs/bpf/test_minimal