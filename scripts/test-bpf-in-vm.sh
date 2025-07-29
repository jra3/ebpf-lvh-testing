#!/bin/bash
# Script that runs inside VMs to load and verify BPF programs

set -e

PROG_DIR="/host/src/bpf"
RESULTS_FILE="/host/test-results.json"

echo "=== BPF Test Runner (Inside VM) ==="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"

# Check if we have the necessary tools
echo -e "\n--- Checking tools ---"
for tool in bpftool mount; do
    if ! command -v $tool &> /dev/null; then
        echo "❌ Missing required tool: $tool"
        exit 1
    fi
done
echo "✅ All required tools present"

# Ensure BPF filesystem is mounted
echo -e "\n--- Checking BPF filesystem ---"
if ! mount | grep -q "type bpf"; then
    echo "Mounting BPF filesystem..."
    sudo mount -t bpf bpf /sys/fs/bpf || {
        echo "❌ Failed to mount BPF filesystem"
        exit 1
    }
fi
echo "✅ BPF filesystem mounted"

# Change to program directory
cd "$PROG_DIR"

# Initialize results
echo "{" > "$RESULTS_FILE"
echo "  \"kernel\": \"$(uname -r)\"," >> "$RESULTS_FILE"
echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$RESULTS_FILE"
echo "  \"programs\": {" >> "$RESULTS_FILE"

# Test each BPF program
FIRST=true
SUCCESS_COUNT=0
TOTAL_COUNT=0

for prog in *.o; do
    [ -f "$prog" ] || continue
    
    TOTAL_COUNT=$((TOTAL_COUNT + 1))
    
    # Add comma for JSON formatting
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo "," >> "$RESULTS_FILE"
    fi
    
    echo -e "\n--- Testing $prog ---"
    echo -n "    \"$prog\": {" >> "$RESULTS_FILE"
    
    # Try to load the program
    OUTPUT=$(bpftool prog load "$prog" /sys/fs/bpf/test_prog 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ $prog loaded successfully"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        
        # Get program info
        PROG_INFO=$(bpftool prog show name test_prog -j 2>/dev/null || echo "{}")
        
        echo "\"status\": \"success\"," >> "$RESULTS_FILE"
        echo "\"verifier_log\": \"\"," >> "$RESULTS_FILE"
        echo "\"prog_info\": $PROG_INFO" >> "$RESULTS_FILE"
        
        # Cleanup
        rm -f /sys/fs/bpf/test_prog
    else
        echo "❌ $prog failed to load"
        echo "Verifier output:"
        echo "$OUTPUT"
        
        # Escape the output for JSON
        ESCAPED_OUTPUT=$(echo "$OUTPUT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g' | tr '\n' ' ')
        
        echo "\"status\": \"failed\"," >> "$RESULTS_FILE"
        echo "\"verifier_log\": \"$ESCAPED_OUTPUT\"," >> "$RESULTS_FILE"
        echo "\"prog_info\": null" >> "$RESULTS_FILE"
    fi
    
    echo -n "}" >> "$RESULTS_FILE"
done

# Close JSON
echo -e "\n  }," >> "$RESULTS_FILE"
echo "  \"summary\": {" >> "$RESULTS_FILE"
echo "    \"total\": $TOTAL_COUNT," >> "$RESULTS_FILE"
echo "    \"passed\": $SUCCESS_COUNT," >> "$RESULTS_FILE"
echo "    \"failed\": $((TOTAL_COUNT - SUCCESS_COUNT))" >> "$RESULTS_FILE"
echo "  }" >> "$RESULTS_FILE"
echo "}" >> "$RESULTS_FILE"

# Final summary
echo -e "\n=== Test Summary ==="
echo "Total programs: $TOTAL_COUNT"
echo "Passed: $SUCCESS_COUNT"
echo "Failed: $((TOTAL_COUNT - SUCCESS_COUNT))"

if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "\n✅ All BPF programs passed verification on kernel $(uname -r)"
    exit 0
else
    echo -e "\n❌ Some BPF programs failed verification"
    exit 1
fi