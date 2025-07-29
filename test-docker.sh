#!/bin/bash
# Test BPF programs in Docker containers with different distributions

set -e

echo "=== Docker-based BPF Testing ==="
echo "Note: This tests with different userspace but same kernel"
echo ""

# Build BPF programs first
echo "--- Building BPF programs ---"
cd src/bpf
make clean all
cd ../..

# Test in different containers
for distro in ubuntu:22.04 ubuntu:24.04 debian:12; do
    echo -e "\n--- Testing in $distro ---"
    
    docker run --rm --privileged \
        -v $(pwd):/workspace \
        -w /workspace \
        $distro \
        bash -c '
            apt-get update -qq && apt-get install -y -qq bpftool > /dev/null 2>&1
            echo "Container: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
            echo "Kernel: $(uname -r)"
            
            cd src/bpf
            for prog in *.o; do
                echo -n "  Loading $prog: "
                if bpftool prog load "$prog" /sys/fs/bpf/test_${prog%.o} 2>/dev/null; then
                    echo "✅"
                    rm -f /sys/fs/bpf/test_${prog%.o}
                else
                    echo "❌"
                    exit 1
                fi
            done
        '
done

echo -e "\n=== All container tests passed! ==="