# GitHub Setup Instructions

Follow these steps to create the repository and test the workflow:

## 1. Create GitHub Repository

Go to https://github.com/new and create a new repository with:
- Repository name: `ebpf-lvh-testing` (or your preferred name)
- Description: "Example of testing eBPF programs across kernel versions using LVH"
- Public repository (so Actions run for free)
- Do NOT initialize with README, .gitignore, or license

## 2. Push Code to GitHub

After creating the empty repository, run these commands:

```bash
# Add your GitHub repository as remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/ebpf-lvh-testing.git

# Push the code
git push -u origin main
```

## 3. Enable GitHub Actions

GitHub Actions should be enabled by default. The workflow will trigger automatically on push.

## 4. Monitor Workflow

1. Go to your repository on GitHub
2. Click on the "Actions" tab
3. You should see the workflow running
4. Click on the workflow run to see detailed logs

## 5. Expected Results

The workflow will:
- Run tests on multiple kernel versions (5.15, 6.1, 6.6, bpf-next)
- Each kernel test will:
  - Download/pull the kernel
  - Compile the eBPF program
  - Start an LVH VM
  - Run tests inside the VM
  - Report results

## Troubleshooting

If the workflow fails:
1. Check the logs in the Actions tab
2. Common issues:
   - Kernel download failures: GitHub's network might be slow, re-run the job
   - VM startup timeout: Increase the sleep time in the workflow
   - BPF compilation errors: Check kernel version compatibility

## Testing Locally First (Optional)

If you have Docker installed, you can test locally:
```bash
docker run -it --rm -v $(pwd):/workspace ubuntu:22.04 bash
cd /workspace
apt-get update && apt-get install -y clang make
make -C src/bpf
```