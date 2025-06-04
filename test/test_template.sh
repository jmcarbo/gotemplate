#!/bin/bash
# Simple template test script for local development
set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "🧪 Testing Go Template Repository"
echo "================================"

# Test 1: Template instantiation
echo -e "\n${GREEN}Test 1: Template Instantiation${NC}"
TEMP_DIR=$(mktemp -d)
cp -r . "$TEMP_DIR/template"
cd "$TEMP_DIR/template"

make setup-project PROJECT_NAME=testapp MODULE_PATH=github.com/test/testapp

# Verify changes
if grep -q "module github.com/test/testapp" go.mod; then
    echo "✅ Module name updated correctly"
else
    echo "❌ Module name not updated"
    exit 1
fi

if grep -q "BINARY_NAME=testapp" Makefile; then
    echo "✅ Binary name updated correctly"
else
    echo "❌ Binary name not updated"
    exit 1
fi

# Test 2: Build
echo -e "\n${GREEN}Test 2: Build${NC}"
if make build; then
    echo "✅ Build successful"
else
    echo "❌ Build failed"
    exit 1
fi

# Test 3: Binary execution
echo -e "\n${GREEN}Test 3: Binary Execution${NC}"
if ./bin/testapp -version; then
    echo "✅ Binary runs successfully"
else
    echo "❌ Binary execution failed"
    exit 1
fi

# Test 4: Tests
echo -e "\n${GREEN}Test 4: Tests${NC}"
if make test; then
    echo "✅ Tests pass"
else
    echo "❌ Tests failed"
    exit 1
fi

# Test 5: Lint
echo -e "\n${GREEN}Test 5: Linting${NC}"
if make lint; then
    echo "✅ Linting passes"
else
    echo "❌ Linting failed"
    exit 1
fi

# Cleanup
cd /
rm -rf "$TEMP_DIR"

echo -e "\n${GREEN}✅ All tests passed!${NC}"