#!/bin/bash

set -e

echo "Installing pre-commit hooks..."

if ! command -v pre-commit &> /dev/null; then
    echo "pre-commit not found. Installing..."
    pip install pre-commit || pip3 install pre-commit
fi

pre-commit install
pre-commit install --hook-type commit-msg

echo "Pre-commit hooks installed successfully!"
echo "Running pre-commit on all files..."
pre-commit run --all-files || true

echo "Setup complete!"