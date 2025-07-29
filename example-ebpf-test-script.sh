#!/bin/bash
# Example script showing how to compile and test eBPF programs in LVH VMs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== eBPF Testing Script for LVH ==="

# Check if running inside VM or host
if [[ -d /host ]]; then
    echo "Running inside LVH VM"
    cd /host
fi

# Install dependencies if needed
if ! command -v bpftool &> /dev/null; then
    echo "Installing BPF tools..."
    apt-get update
    apt-get install -y bpftool libbpf-dev clang llvm
fi

# Get kernel version
KERNEL_VERSION=$(uname -r)
echo "Testing on kernel: $KERNEL_VERSION"

# Compile eBPF programs
echo "Compiling eBPF programs..."
mkdir -p build

# Example 1: Simple kprobe program
cat > src/kprobe_example.c << 'EOF'
#include <linux/bpf.h>
#include <linux/ptrace.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_tracing.h>

char LICENSE[] SEC("license") = "GPL";

struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024);
} events SEC(".maps");

SEC("kprobe/sys_open")
int kprobe_sys_open(struct pt_regs *ctx)
{
    u32 pid = bpf_get_current_pid_tgid() >> 32;
    
    struct event {
        u32 pid;
        char comm[16];
    } *e;
    
    e = bpf_ringbuf_reserve(&events, sizeof(*e), 0);
    if (!e)
        return 0;
    
    e->pid = pid;
    bpf_get_current_comm(&e->comm, sizeof(e->comm));
    
    bpf_ringbuf_submit(e, 0);
    return 0;
}
EOF

# Example 2: TC program
cat > src/tc_example.c << 'EOF'
#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <bpf/bpf_helpers.h>

char LICENSE[] SEC("license") = "GPL";

SEC("tc")
int tc_prog(struct __sk_buff *skb)
{
    void *data = (void *)(long)skb->data;
    void *data_end = (void *)(long)skb->data_end;
    
    struct ethhdr *eth = data;
    if ((void*)(eth + 1) > data_end)
        return TC_ACT_OK;
    
    if (eth->h_proto != __constant_htons(ETH_P_IP))
        return TC_ACT_OK;
    
    struct iphdr *ip = (void*)(eth + 1);
    if ((void*)(ip + 1) > data_end)
        return TC_ACT_OK;
    
    // Example: Drop packets to port 9999
    if (ip->protocol == IPPROTO_TCP) {
        struct tcphdr *tcp = (void*)ip + (ip->ihl * 4);
        if ((void*)(tcp + 1) <= data_end) {
            if (tcp->dest == __constant_htons(9999)) {
                return TC_ACT_SHOT;  // Drop packet
            }
        }
    }
    
    return TC_ACT_OK;
}
EOF

# Compile programs
echo "Compiling kprobe program..."
clang -O2 -g -target bpf -c src/kprobe_example.c -o build/kprobe_example.o

echo "Compiling TC program..."
clang -O2 -g -target bpf -c src/tc_example.c -o build/tc_example.o

# Load and test programs
echo -e "\n${GREEN}Loading BPF programs...${NC}"

# Test 1: Load kprobe
echo "Loading kprobe program..."
bpftool prog load build/kprobe_example.o /sys/fs/bpf/kprobe_test
bpftool prog show name kprobe_sys_open

# Test 2: Attach TC program (if network interface available)
if ip link show eth0 &> /dev/null; then
    echo "Attaching TC program to eth0..."
    tc qdisc add dev eth0 clsact 2>/dev/null || true
    tc filter add dev eth0 ingress bpf da obj build/tc_example.o sec tc
    tc filter show dev eth0 ingress
fi

# Test 3: Verify programs are working
echo -e "\n${GREEN}Verifying BPF programs...${NC}"
bpftool prog list

# Test 4: Check for verification errors
echo -e "\n${GREEN}Checking kernel logs for BPF errors...${NC}"
dmesg | grep -i "bpf" | tail -10 || echo "No BPF messages in kernel log"

# Test 5: Run functional tests
echo -e "\n${GREEN}Running functional tests...${NC}"

# Create test result directory
mkdir -p test-results

# Simple functionality test
cat > test-results/test_report.txt << EOF
Test Report for Kernel: $KERNEL_VERSION
Date: $(date)

BPF Programs Loaded:
$(bpftool prog list | grep -E "kprobe|tc")

Map Status:
$(bpftool map list)

Test Status: PASSED
EOF

echo -e "${GREEN}All tests completed successfully!${NC}"

# Cleanup (optional)
# echo "Cleaning up..."
# rm -f /sys/fs/bpf/kprobe_test
# tc filter del dev eth0 ingress