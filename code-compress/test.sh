#!/bin/bash

# Test script for code-compress.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/code-compress.sh"
TEST_ROOT="$SCRIPT_DIR/test"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

cleanup() {
    echo "Cleaning up..."
    rm -rf "$TEST_ROOT"
}

log_pass() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_fail() { 
    echo -e "${RED}[FAIL]${NC} $1"
    cleanup
    exit 1
}

# Setup
cleanup
mkdir -p "$TEST_ROOT/src"
echo "test data" > "$TEST_ROOT/src/file.txt"

echo "Starting code-compress tests..."

# 1. Test Help
echo "Testing: Help command..."
bash "$SCRIPT_PATH" -h > /dev/null || log_fail "Help command failed"
log_pass "Help command works"

# 2. Test Default Compression (.)
echo "Testing: Default compression..."
(cd "$TEST_ROOT/src" && git init > /dev/null && git config user.email "t@e.com" && git config user.name "T" && git add . && git commit -m "t" > /dev/null && bash "$SCRIPT_PATH" .) > /dev/null || log_fail "Default compression failed"
ls "$TEST_ROOT/src"/*.tar.zst > /dev/null || log_fail "Archive not created in current dir"
log_pass "Default compression created archive in ."

# 3. Test Parent Directory Compression (-1)
echo "Testing: Parent directory compression (-1)..."
(cd "$TEST_ROOT/src" && bash "$SCRIPT_PATH" -1 .) > /dev/null || log_fail "Parent compression failed"
ls "$TEST_ROOT"/*.tar.zst > /dev/null || log_fail "Archive not created in parent dir"
log_pass "Compression with -1 created archive in .."

# 4. Test Custom Output Directory (-o)
echo "Testing: Custom output directory (-o)..."
mkdir -p "$TEST_ROOT/out"
(cd "$TEST_ROOT/src" && bash "$SCRIPT_PATH" -o "$TEST_ROOT/out" .) > /dev/null || log_fail "Custom output dir failed"
ls "$TEST_ROOT/out"/*.tar.zst > /dev/null || log_fail "Archive not created in custom -o dir"
log_pass "Compression with -o worked"

# 5. Test -lfast (lz4)
echo "Testing: lz4 compression (-lfast)..."
(cd "$TEST_ROOT/src" && bash "$SCRIPT_PATH" -lfast -o "$TEST_ROOT/lz4" .) > /dev/null || log_fail "lz4 compression failed"
ls "$TEST_ROOT/lz4"/*.tar.lz4 > /dev/null || log_fail "lz4 archive not created"
log_pass "Compression with -lfast created .tar.lz4"

# 6. Test ls command
echo "Testing: ls command..."
output=$(bash "$SCRIPT_PATH" ls "$TEST_ROOT/lz4")
echo "$output" | grep "src" > /dev/null || log_fail "ls command did not list archives"
log_pass "ls command works with path"

# 7. Test extraction
echo "Testing: Extraction..."
ARCHIVE=$(ls "$TEST_ROOT/out"/*.tar.zst | head -n 1)
mkdir -p "$TEST_ROOT/extract"
(cd "$TEST_ROOT/extract" && bash "$SCRIPT_PATH" "$ARCHIVE") > /dev/null || log_fail "Extraction failed"
ls "$TEST_ROOT/extract"/*/file.txt > /dev/null || log_fail "Extracted file not found"
log_pass "Extraction works"

# 8. Test Git repository naming (mocking a git repo)
echo "Testing: Git repository integration..."
mkdir -p "$TEST_ROOT/git-repo"
(
    cd "$TEST_ROOT/git-repo"
    git init > /dev/null
    git config user.email "test@example.com"
    git config user.name "Test User"
    echo "git data" > data.txt
    git add .
    git commit -m "initial" > /dev/null
    bash "$SCRIPT_PATH" . > /dev/null
) || log_fail "Git compression failed"
# The format is REPO_NAME-HEX-REV.tar.zst
ls "$TEST_ROOT/git-repo"/git-repo-*-*.tar.zst > /dev/null || log_fail "Git archive name incorrect"
log_pass "Git repository naming and revision work"

echo -e "\n${GREEN}All tests passed!${NC}"
cleanup
