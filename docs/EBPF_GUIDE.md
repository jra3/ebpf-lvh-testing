# eBPF Development Guide

## Introduction to eBPF

eBPF (extended Berkeley Packet Filter) is a revolutionary technology that allows running sandboxed programs in the Linux kernel without changing kernel source code or loading kernel modules.

## Writing eBPF Programs

### Basic Structure

```c
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>

// License is required for kernel to load the program
char LICENSE[] SEC("license") = "GPL";

// Define your BPF program in a specific section
SEC("kprobe/sys_open")
int trace_open(struct pt_regs *ctx) {
    // Your code here
    return 0;
}
```

### Program Types

1. **kprobe/kretprobe** - Trace kernel functions
2. **tracepoint** - Trace kernel tracepoints
3. **xdp** - Process packets at driver level
4. **tc** - Traffic control (network)
5. **cgroup** - Control group programs
6. **perf_event** - Performance monitoring

### Maps (Data Structures)

```c
// Hash map example
struct {
    __uint(type, BPF_MAP_TYPE_HASH);
    __uint(max_entries, 1024);
    __type(key, u32);
    __type(value, u64);
} counts SEC(".maps");

// Array map example
struct {
    __uint(type, BPF_MAP_TYPE_ARRAY);
    __uint(max_entries, 256);
    __type(key, u32);
    __type(value, struct event);
} events SEC(".maps");

// Ring buffer for event streaming
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024);
} rb SEC(".maps");
```

## Compilation

### Using Clang

```bash
# Basic compilation
clang -O2 -target bpf -c program.c -o program.o

# With debug info
clang -O2 -g -target bpf -c program.c -o program.o

# With includes
clang -O2 -target bpf \
    -I/usr/include/bpf \
    -c program.c -o program.o
```

### Makefile Template

```makefile
CLANG ?= clang
ARCH := $(shell uname -m | sed 's/x86_64/x86/')

BPF_CFLAGS := -target bpf \
    -D__TARGET_ARCH_$(ARCH) \
    -I/usr/include/$(shell uname -m)-linux-gnu \
    -Wall \
    -O2 -g

%.o: %.c
    $(CLANG) $(BPF_CFLAGS) -c $< -o $@

clean:
    rm -f *.o
```

## Loading and Testing

### Using bpftool

```bash
# Load program
sudo bpftool prog load program.o /sys/fs/bpf/my_prog

# List loaded programs
sudo bpftool prog list

# Show program details
sudo bpftool prog show name my_prog

# Attach to kprobe
sudo bpftool prog attach id <prog_id> kprobe sys_open

# View map contents
sudo bpftool map dump name counts
```

### Using libbpf

```c
#include <bpf/libbpf.h>
#include <bpf/bpf.h>

int main() {
    struct bpf_object *obj;
    struct bpf_program *prog;
    struct bpf_link *link;
    
    // Open BPF object file
    obj = bpf_object__open_file("program.o", NULL);
    if (!obj) return -1;
    
    // Load into kernel
    if (bpf_object__load(obj)) return -1;
    
    // Find and attach program
    prog = bpf_object__find_program_by_name(obj, "trace_open");
    link = bpf_program__attach(prog);
    
    // Main loop
    sleep(60);
    
    // Cleanup
    bpf_link__destroy(link);
    bpf_object__close(obj);
    return 0;
}
```

## Best Practices

### 1. Error Handling
Always check return values and handle errors gracefully:

```c
void *data = bpf_map_lookup_elem(&my_map, &key);
if (!data)
    return 0; // Handle lookup failure
```

### 2. Bounded Loops
The verifier requires bounded loops:

```c
#pragma unroll
for (int i = 0; i < 10; i++) {
    // Loop body
}
```

### 3. Stack Usage
Keep stack usage under 512 bytes:

```c
// Bad: Large stack allocation
char buffer[1024]; // Too large!

// Good: Use maps for large data
struct large_data *data = bpf_map_lookup_elem(&data_map, &key);
```

### 4. Helper Functions
Use BPF helper functions for kernel interaction:

```c
// Get current PID/TID
u64 pid_tgid = bpf_get_current_pid_tgid();
u32 pid = pid_tgid >> 32;
u32 tid = (u32)pid_tgid;

// Get current time
u64 ts = bpf_ktime_get_ns();

// Copy string from userspace
bpf_probe_read_user_str(buf, sizeof(buf), user_ptr);
```

## Debugging Tips

### 1. Verifier Errors
Understanding common verifier errors:

- "invalid access to map value" - Check bounds
- "unreachable insn" - Check control flow
- "back-edge from insn X to Y" - Loop not bounded

### 2. Using bpf_printk
Debug output to trace pipe:

```c
bpf_printk("Debug: pid=%d value=%d\n", pid, value);
```

View output:
```bash
sudo cat /sys/kernel/debug/tracing/trace_pipe
```

### 3. Dumping Bytecode
Inspect compiled BPF bytecode:

```bash
llvm-objdump -d program.o
bpftool prog dump xlated id <prog_id>
```

## Kernel Compatibility

Different kernel versions support different features:

- 4.14+ - Basic BPF features
- 4.18+ - bpf2bpf calls
- 5.2+ - Global data
- 5.7+ - LSM hooks
- 5.10+ - Sleepable programs
- 5.13+ - Kernel module BTF

Always test on target kernel versions!