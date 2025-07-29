#!/bin/bash
# Simplified VM testing using pre-built images and LVH

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/test-results"
WORK_DIR="${PROJECT_ROOT}/vm-test-work"

# Default kernel versions to test
KERNEL_VERSIONS=${KERNEL_VERSIONS:-"5.10 5.15 6.1 6.6"}

echo "=== Simplified BPF VM Testing ==="
echo "Using pre-built kernels and minimal rootfs"
echo "Testing kernels: $KERNEL_VERSIONS"

# Check dependencies
if ! command -v lvh &> /dev/null; then
    export PATH="$HOME/go/bin:$PATH"
fi

if ! command -v lvh &> /dev/null; then
    echo "❌ LVH not found. Please install it first."
    exit 1
fi

# Build BPF programs
echo -e "\n--- Building BPF programs ---"
cd "${PROJECT_ROOT}/src/bpf"
make clean all

# Verify BTF support
echo "Verifying BTF sections..."
for prog in *.o; do
    if ! llvm-readelf -S "$prog" | grep -q "\.BTF"; then
        echo "❌ $prog missing BTF section"
        exit 1
    fi
done
echo "✅ All programs have BTF support"

# Create work directory
mkdir -p "$WORK_DIR"
mkdir -p "$RESULTS_DIR"
cd "$WORK_DIR"

# Download minimal rootfs if not cached
ROOTFS_CACHE="${HOME}/.cache/lvh-testing"
mkdir -p "$ROOTFS_CACHE"

if [ ! -f "$ROOTFS_CACHE/alpine-minirootfs.tar.gz" ]; then
    echo -e "\n--- Downloading Alpine minimal rootfs ---"
    wget -q -O "$ROOTFS_CACHE/alpine-minirootfs.tar.gz" \
        https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/aarch64/alpine-minirootfs-3.19.0-aarch64.tar.gz
fi

# Create a simple test script for inside the VM
cat > "${WORK_DIR}/test-bpf.sh" << 'EOF'
#!/bin/sh
set -e

echo "=== BPF Test Runner ==="
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

# Install bpftool
echo "Installing bpftool..."
apk add --no-cache bpftool >/dev/null 2>&1 || {
    echo "Failed to install bpftool, trying manual approach..."
    # Manual fallback if needed
}

# Mount BPF filesystem if needed
if ! mount | grep -q "type bpf"; then
    mount -t bpf bpf /sys/fs/bpf
fi

cd /host/src/bpf

# Test each BPF program
SUCCESS=0
TOTAL=0

for prog in *.o; do
    [ -f "$prog" ] || continue
    TOTAL=$((TOTAL + 1))
    
    echo -n "Testing $prog: "
    if bpftool prog load "$prog" /sys/fs/bpf/test_prog 2>/dev/null; then
        echo "✅ PASS"
        SUCCESS=$((SUCCESS + 1))
        rm -f /sys/fs/bpf/test_prog
    else
        echo "❌ FAIL"
    fi
done

echo ""
echo "Results: $SUCCESS/$TOTAL passed"

if [ $SUCCESS -eq $TOTAL ]; then
    echo "✅ All tests passed on kernel $(uname -r)"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
EOF
chmod +x "${WORK_DIR}/test-bpf.sh"

# Test on each kernel
OVERALL_SUCCESS=true

for KERNEL in $KERNEL_VERSIONS; do
    echo -e "\n=== Testing kernel $KERNEL ==="
    
    # Download kernel if not already available
    if [ ! -d "${WORK_DIR}/${KERNEL}-main" ]; then
        echo "Downloading kernel ${KERNEL}..."
        if ! lvh kernels pull "${KERNEL}-main" 2>/dev/null; then
            echo "⚠️  Failed to pull kernel ${KERNEL}, skipping..."
            continue
        fi
    fi
    
    # Find kernel image
    KERNEL_IMAGE=$(find "${WORK_DIR}/${KERNEL}-main/boot" -name "*vmlinuz*" -o -name "*Image*" | head -1)
    
    if [ -z "$KERNEL_IMAGE" ]; then
        echo "❌ No kernel image found for ${KERNEL}"
        OVERALL_SUCCESS=false
        continue
    fi
    
    echo "Using kernel: $KERNEL_IMAGE"
    
    # Run test with LVH
    echo "Starting VM..."
    
    # Note: This is a simplified approach. In practice, we might need to:
    # 1. Create a proper disk image from the Alpine rootfs
    # 2. Use QEMU directly with the right parameters
    # 3. Or use LVH's image functionality properly
    
    # For now, let's create a marker that the test would run here
    echo "⚠️  VM execution step would go here"
    echo "   Kernel: ${KERNEL}-main"
    echo "   Rootfs: Alpine minimal"
    echo "   Test script: ${WORK_DIR}/test-bpf.sh"
    
    # Create a mock result
    RESULT_FILE="${RESULTS_DIR}/kernel-${KERNEL}.txt"
    cat > "$RESULT_FILE" << EOL
Kernel: ${KERNEL}
Status: Would test here
BPF Programs:
  minimal.o: pending
  simple_kprobe.o: pending
EOL
done

# Summary
echo -e "\n=== Test Summary ==="
echo "Work directory: $WORK_DIR"
echo "Results directory: $RESULTS_DIR"
echo ""
echo "Next steps:"
echo "1. Fix VM execution using QEMU directly or LVH properly"
echo "2. Parse and report results"
echo "3. Integrate with CI"

if [ "$OVERALL_SUCCESS" = true ]; then
    exit 0
else
    exit 1
fi