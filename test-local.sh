#!/bin/bash
# Simple local test script for BPF programs

set -e

echo "=== Local BPF Testing ==="
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""

# Build BPF programs
echo "--- Building BPF programs ---"
cd src/bpf
make clean all

# Verify BTF sections
echo -e "\n--- Verifying BTF support ---"
for prog in *.o; do
    echo -n "$prog: "
    if llvm-readelf -S "$prog" | grep -q "\.BTF"; then
        echo "✅ Has BTF"
    else
        echo "❌ Missing BTF"
        exit 1
    fi
done

# Test loading each program
echo -e "\n--- Testing BPF program loading ---"
for prog in *.o; do
    echo -n "Loading $prog: "
    if sudo bpftool prog load "$prog" /sys/fs/bpf/test_${prog%.o} 2>/dev/null; then
        echo "✅ Success"
        # Show program info
        sudo bpftool prog show pinned /sys/fs/bpf/test_${prog%.o} | grep -E "name|tag|loaded_at"
        # Clean up
        sudo rm -f /sys/fs/bpf/test_${prog%.o}
    else
        echo "❌ Failed"
        exit 1
    fi
    echo ""
done

echo "=== All tests passed! ==="
echo "Your BPF programs are compatible with kernel $(uname -r)"