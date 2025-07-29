#!/bin/bash
# Script to build VM images using LVH for BPF testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGES_DIR="${PROJECT_ROOT}/vm-images"

echo "Building VM images for BPF testing..."

# Check if LVH is installed
if ! command -v lvh &> /dev/null; then
    echo "Error: LVH is not installed. Please install it first."
    echo "Visit: https://github.com/cilium/little-vm-helper"
    exit 1
fi

# Create images directory
mkdir -p "${IMAGES_DIR}"

# Build the image
echo "Building BPF test image..."
cd "${PROJECT_ROOT}"

# Use LVH to build the image based on images.json
# LVH expects images.json in the current directory or specified with full path
echo "Config file: ${PROJECT_ROOT}/images.json"
echo "Output dir: ${IMAGES_DIR}"
echo "Current dir: $(pwd)"

# Copy images.json to where LVH expects it or use the right syntax
cd "${PROJECT_ROOT}"

# Try different LVH syntaxes based on version
if lvh images build --help 2>&1 | grep -q "config"; then
    # Newer syntax with --config
    lvh images build \
        --config "${PROJECT_ROOT}/images.json" \
        --dir "${IMAGES_DIR}" \
        bpf-test
else
    # Older syntax - LVH looks for images.json in current dir
    lvh images build \
        --dir "${IMAGES_DIR}" \
        --image bpf-test
fi

echo "VM image built successfully!"
echo "Image location: ${IMAGES_DIR}"

# List the generated images
echo -e "\nGenerated images:"
ls -la "${IMAGES_DIR}/"

echo -e "\nBuild complete!"