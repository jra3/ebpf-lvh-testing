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
lvh images build \
    --dir "${IMAGES_DIR}" \
    --image bpf-test

echo "VM image built successfully!"
echo "Image location: ${IMAGES_DIR}"

# List the generated images
echo -e "\nGenerated images:"
ls -la "${IMAGES_DIR}/"

echo -e "\nBuild complete!"