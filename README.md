# eBPF Testing with LVH (Little VM Helper)

[![CI](https://github.com/jra3/ebpf-lvh-testing/actions/workflows/ci.yml/badge.svg)](https://github.com/jra3/ebpf-lvh-testing/actions/workflows/ci.yml)

This repository demonstrates how to test eBPF programs across multiple kernel versions using GitHub Actions and LVH (Little VM Helper).

## Overview

Testing eBPF programs across different kernel versions is crucial for compatibility but can be challenging. This project provides:

- ✅ Automated eBPF compilation testing across kernel versions 5.10, 5.15, 6.1, and 6.6
- ✅ GitHub Actions CI/CD pipeline for continuous testing
- ✅ Example eBPF programs and test infrastructure
- ✅ Instructions for local VM-based testing with LVH

## Project Structure

```
.
├── src/bpf/          # eBPF source files
│   ├── Makefile      # Build configuration
│   ├── minimal.c     # Minimal eBPF example
│   └── simple_kprobe.c # Kprobe example
├── scripts/          # Test scripts
│   └── run_tests.sh  # Script to run inside VMs
├── .github/workflows/
│   └── ci.yml        # GitHub Actions workflow
└── docs/             # Additional documentation
```

## Quick Start

### Prerequisites

- Linux development environment
- Clang/LLVM for eBPF compilation
- Go 1.21+ (for LVH)
- Git

### Building eBPF Programs

```bash
# Clone the repository
git clone git@github.com:jra3/ebpf-lvh-testing.git
cd ebpf-lvh-testing

# Build eBPF programs
make -C src/bpf clean all

# Verify compilation
ls -la src/bpf/*.o
```

### Running Tests Locally

1. **Install LVH:**
   ```bash
   go install github.com/cilium/little-vm-helper/cmd/lvh@latest
   export PATH="$PATH:$(go env GOPATH)/bin"
   ```

2. **Build VM Images:**
   ```bash
   # Generate example configuration
   lvh images example-config > images.json
   
   # Edit images.json as needed, then build
   lvh images build --dir .
   ```

3. **Run Tests in VM:**
   ```bash
   # Pull a kernel
   lvh kernels pull 6.1-main
   
   # Run VM with your eBPF programs
   lvh run --image _data/images/base.qcow2 \
           --kernel <path-to-kernel> \
           --host-mount $(pwd)
   
   # Inside the VM
   cd /host
   ./scripts/run_tests.sh
   ```

## GitHub Actions CI

The CI workflow automatically:

1. Compiles eBPF programs for multiple kernel versions
2. Validates object file format and bytecode
3. Verifies BPF section headers
4. Provides test results for each kernel version

View the latest test results: [GitHub Actions](https://github.com/jra3/ebpf-lvh-testing/actions)

## Writing eBPF Programs

### Example: Minimal BPF Program

```c
// src/bpf/minimal.c
typedef unsigned int __u32;

#define SEC(NAME) __attribute__((section(NAME), used))

char LICENSE[] SEC("license") = "GPL";

SEC("kprobe/sys_open")
int minimal_prog(void *ctx)
{
    return 0;
}
```

### Building Your Program

Add your eBPF program to `src/bpf/` and it will be automatically built by the Makefile.

## Testing Strategy

### CI Testing (GitHub Actions)
- Compilation verification
- Object file validation
- Bytecode inspection
- Multi-kernel compatibility checks

### Local VM Testing
- Full BPF program loading
- Runtime verification
- Kernel-specific behavior testing
- Performance analysis

## Troubleshooting

### Common Issues

1. **BPF Compilation Errors**
   - Ensure you have clang-15 or newer
   - Check kernel headers are available

2. **LVH Issues**
   - LVH requires Go 1.21+
   - VM images must be built locally
   - Check QEMU is installed for VM support

3. **GitHub Actions Failures**
   - Ubuntu 24.04 runners don't have `bpftool` package
   - Use the provided CI workflow which works around this

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure CI passes
5. Submit a pull request

## Resources

- [LVH Documentation](https://github.com/cilium/little-vm-helper)
- [eBPF Documentation](https://ebpf.io/)
- [Linux Kernel BPF Documentation](https://www.kernel.org/doc/html/latest/bpf/)

## License

This project is licensed under the MIT License - see the LICENSE file for details.