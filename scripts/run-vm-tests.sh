#!/bin/bash
# Orchestrator script to run BPF tests across multiple kernel versions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/test-results"

# Default kernel versions to test
KERNEL_VERSIONS=${KERNEL_VERSIONS:-"5.10 5.15 6.1 6.6"}

echo "=== BPF Cross-Kernel Testing Orchestrator ==="
echo "Testing kernels: $KERNEL_VERSIONS"

# Check dependencies
echo -e "\n--- Checking dependencies ---"

if ! command -v lvh &> /dev/null; then
    echo "❌ LVH not found. Please install: https://github.com/cilium/little-vm-helper"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "⚠️  jq not found. JSON results will not be parsed."
    JQ_AVAILABLE=false
else
    JQ_AVAILABLE=true
fi

echo "✅ Dependencies satisfied"

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

# Create results directory
mkdir -p "$RESULTS_DIR"

# Build VM image if needed
if [ ! -f "${PROJECT_ROOT}/vm-images/bpf-test.qcow2" ]; then
    echo -e "\n--- Building VM image ---"
    "${SCRIPT_DIR}/build-vm-images.sh"
fi

# Test on each kernel
OVERALL_SUCCESS=true

for KERNEL in $KERNEL_VERSIONS; do
    echo -e "\n=== Testing kernel $KERNEL ==="
    
    RESULT_FILE="${RESULTS_DIR}/kernel-${KERNEL}.json"
    
    # Pull kernel if not already available
    echo "Pulling kernel ${KERNEL}..."
    if ! lvh kernels pull "${KERNEL}-main" 2>/dev/null; then
        echo "⚠️  Failed to pull kernel ${KERNEL}, skipping..."
        continue
    fi
    
    # Run test in VM
    echo "Starting VM with kernel ${KERNEL}..."
    
    if timeout 300 lvh run \
        --kernel "${KERNEL}-main" \
        --image "${PROJECT_ROOT}/vm-images/bpf-test.qcow2" \
        --host-mount "${PROJECT_ROOT}" \
        --daemonize=false \
        --serial-port stdio \
        -- /host/scripts/test-bpf-in-vm.sh; then
        
        echo "✅ Tests passed on kernel ${KERNEL}"
        
        # Copy results
        if [ -f "${PROJECT_ROOT}/test-results.json" ]; then
            mv "${PROJECT_ROOT}/test-results.json" "$RESULT_FILE"
        fi
    else
        echo "❌ Tests failed on kernel ${KERNEL}"
        OVERALL_SUCCESS=false
    fi
done

# Generate summary report
echo -e "\n=== Generating Summary Report ==="

SUMMARY_FILE="${RESULTS_DIR}/summary.md"
cat > "$SUMMARY_FILE" << EOF
# BPF Cross-Kernel Test Results

Generated: $(date)

## Summary

| Kernel | Status | Details |
|--------|--------|---------|
EOF

for KERNEL in $KERNEL_VERSIONS; do
    RESULT_FILE="${RESULTS_DIR}/kernel-${KERNEL}.json"
    
    if [ -f "$RESULT_FILE" ] && [ "$JQ_AVAILABLE" = true ]; then
        TOTAL=$(jq -r '.summary.total' "$RESULT_FILE")
        PASSED=$(jq -r '.summary.passed' "$RESULT_FILE")
        STATUS="✅ Passed"
        
        if [ "$PASSED" != "$TOTAL" ]; then
            STATUS="❌ Failed"
        fi
        
        echo "| $KERNEL | $STATUS | $PASSED/$TOTAL programs passed |" >> "$SUMMARY_FILE"
    else
        echo "| $KERNEL | ⚠️  No results | - |" >> "$SUMMARY_FILE"
    fi
done

echo "" >> "$SUMMARY_FILE"
echo "## Detailed Results" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "See individual result files in \`test-results/\` directory." >> "$SUMMARY_FILE"

# Display summary
echo -e "\n--- Test Summary ---"
cat "$SUMMARY_FILE"

# Exit with appropriate code
if [ "$OVERALL_SUCCESS" = true ]; then
    echo -e "\n✅ All tests passed!"
    exit 0
else
    echo -e "\n❌ Some tests failed!"
    exit 1
fi