# Implementation Plan: eBPF Testing with CO-RE and VMs

## Overview

Implement proper eBPF testing that:
1. Compiles eBPF programs ONCE on the host with CO-RE support
2. Runs multiple VMs with different kernel versions
3. Loads the same bytecode in each VM using bpftool
4. Validates that the BPF verifier accepts the program on each kernel

## Task Breakdown

### 1. Update eBPF Programs for CO-RE Support

**Goal**: Make eBPF programs portable across kernel versions using CO-RE

**Steps**:
- Generate or include vmlinux.h for BTF type definitions
- Update eBPF programs to use CO-RE macros (BPF_CORE_READ, etc.)
- Modify Makefile to compile with BTF support (-g flag and proper target)
- Ensure programs use BTF-based type information instead of kernel headers

**Files to modify**:
- `src/bpf/minimal.c`
- `src/bpf/simple_kprobe.c`
- `src/bpf/Makefile`
- Add `src/bpf/vmlinux.h` (generated)

### 2. Create VM Image Configuration for LVH

**Goal**: Build VM images that include necessary tools for BPF testing

**Steps**:
- Create `images.json` with packages: bpftool, libbpf-dev, make, etc.
- Add script to build images in CI
- Ensure images work with different kernel versions

**Files to create**:
- `images.json` - LVH image configuration
- `scripts/build-vm-images.sh` - Image building script

### 3. Update CI Workflow for VM-Based Testing

**Goal**: Run actual VMs in GitHub Actions and test BPF programs

**Steps**:
- Install LVH and dependencies
- Build VM images (or cache them)
- Pull kernels for each version
- For each kernel:
  - Start VM with that kernel
  - Mount host directory with compiled BPF programs
  - Run test script inside VM
  - Collect results
- Report success/failure matrix

**Files to modify**:
- `.github/workflows/ci.yml` - Complete rewrite for VM testing

### 4. Create Test Scripts for Inside VMs

**Goal**: Scripts that run inside VMs to load and verify BPF programs

**Steps**:
- Create script that loads BPF programs with bpftool
- Verify programs loaded successfully
- Check for verifier errors
- Report results in a structured format
- Handle errors gracefully

**Files to create**:
- `scripts/test-bpf-in-vm.sh` - Main test script for inside VMs
- `scripts/run-vm-tests.sh` - Orchestrator script for host

## Expected Outcome

After implementation:
- Single compilation of BPF programs with CO-RE on host
- Same bytecode tested on kernels 5.10, 5.15, 6.1, 6.6
- Real kernel BPF verifier validation
- CI reports which kernels accept/reject the programs
- True cross-kernel compatibility testing

## Success Criteria

- [ ] BPF programs compile with BTF/CO-RE support
- [ ] VM images build successfully with required tools
- [ ] VMs start in GitHub Actions (even without KVM)
- [ ] BPF programs load successfully in all target kernel versions
- [ ] CI provides clear pass/fail for each kernel version
- [ ] Documentation updated to reflect actual testing