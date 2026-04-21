#!/bin/bash

# Extraction logic
if [[ "$1" == *.tar.zst ]]; then
    if [[ -f "$1" ]]; then
        # Determine the target directory name (strip .tar.zst)
        TARGET_DIR=$(basename "$1" .tar.zst)
        echo "Extracting $1 to $TARGET_DIR..."

        # Create the directory if it doesn't exist
        mkdir -p "$TARGET_DIR"

        # Decompress and extract into the target directory
        zstd -d -c "$1" | tar -xf - -C "$TARGET_DIR"

        if [ $? -eq 0 ]; then
            echo "Success! Extracted to $TARGET_DIR"
            exit 0
        else
            echo "Error: Extraction failed."
            exit 1
        fi
    else
        echo "Error: File $1 not found."
        exit 1
    fi
fi

# Configuration
HEX_TIME=$(printf '%x' $(date +%s))
COMPRESSION_LEVEL="-19"
THREADS="-T0"

# Add global directories to skip here
# These will be passed to both git and rsync/tar
EXCLUDES=(
    "node_modules"
    "bin"
    "build"
    ".cache"
    "dist"
    "target" # Rust
    ".git"
    "*.o"    # C object files
    "*.pyc"  # Python bytecode
)

echo "Checking environment..."

# Build the exclude string for 'git archive'
# Git uses pathspecs: ':(exclude)path'
GIT_EXCLUDES=()
for item in "${EXCLUDES[@]}"; do
    GIT_EXCLUDES+=(":(exclude)$item")
done

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
    SHORT_HASH=$(git rev-parse --short HEAD)
    OUT_FILE="../${REPO_NAME}-${HEX_TIME}-${SHORT_HASH}.tar.zst"
    echo "Detected Git repository: $REPO_NAME ($SHORT_HASH). Using 'git archive'..."
    # git archive HEAD [pathspecs...]
    git archive --format=tar HEAD . "${GIT_EXCLUDES[@]}" | \
    zstd -f $THREADS $COMPRESSION_LEVEL -o "$OUT_FILE"

else
    DIR_NAME=$(basename "$(pwd)")
    OUT_FILE="../${DIR_NAME}-${HEX_TIME}.tar.zst"
    echo "Not a Git repository. Falling back to rsync + tar..."

    # Build rsync exclude flags
    RSYNC_EXCLUDES=()
    for item in "${EXCLUDES[@]}"; do
        RSYNC_EXCLUDES+=("--exclude=$item")
    done

    # Use rsync with a dummy destination to get a clean file list
    # We use a unique prefix '###' to filter out rsync headers
    rsync -a --filter=':- .gitignore' "${RSYNC_EXCLUDES[@]}" --dry-run ./ ./DUMMY_DEST/ --out-format="###%n" | \
    grep "^###" | sed "s/^###//" | \
    tar -cf - --no-recursion -T - | \
    zstd -f $THREADS $COMPRESSION_LEVEL -o "$OUT_FILE"
fi

if [ $? -eq 0 ]; then
    echo "---"
    echo "Success! Archive created at: $OUT_FILE"
    du -h "$OUT_FILE"
else
    echo "Error: Compression failed."
    exit 1
fi
