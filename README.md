# eBPF LVH Testing Example

This repository demonstrates how to use LVH (Little VM Helper) to test eBPF programs across multiple kernel versions in GitHub Actions.

## Overview

LVH enables automated testing of eBPF programs on different kernel versions without maintaining multiple physical or virtual machines. This is particularly useful for:

- Testing eBPF compatibility across kernel versions
- CI/CD pipelines for kernel-level code
- Automated regression testing

## Project Structure

```
.
├── src/bpf/          # eBPF source files
├── tests/            # Test scripts
├── scripts/          # Helper scripts
└── .github/workflows # GitHub Actions workflows
```

## Features

- Multi-kernel testing (5.15, 6.1, 6.6, bpf-next)
- Automated eBPF compilation
- VM-based isolated testing environment
- GitHub Actions integration

## Quick Start

1. Clone the repository
2. Push to GitHub
3. GitHub Actions will automatically run tests on push/PR

## Local Testing

Install LVH:
```bash
go install github.com/cilium/little-vm-helper/cmd/lvh@latest
```

Run tests locally:
```bash
./scripts/run_tests.sh
```

## Workflow Details

The GitHub workflow:
1. Installs LVH and dependencies
2. Pulls pre-built kernels or builds from source
3. Compiles eBPF programs
4. Runs tests in isolated VMs
5. Reports results

See `.github/workflows/test.yml` for implementation details.