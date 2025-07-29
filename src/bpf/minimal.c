/* Minimal BPF program for testing */
typedef unsigned int __u32;
typedef long long unsigned int __u64;

#define SEC(NAME) __attribute__((section(NAME), used))

char LICENSE[] SEC("license") = "GPL";

SEC("kprobe/sys_open")
int minimal_prog(void *ctx)
{
    return 0;
}