/* Minimal BPF program for testing with CO-RE support */
#include "vmlinux.h"
#include <bpf/bpf_helpers.h>

char LICENSE[] SEC("license") = "GPL";

SEC("kprobe/sys_open")
int minimal_prog(void *ctx)
{
    return 0;
}