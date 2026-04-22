#!/bin/bash

# Portable helper to format bytes into human readable units (KiB, MiB, etc.)
format_bytes() {
    local bytes=$1
    if [[ -z "$bytes" || "$bytes" == "0" ]]; then echo "0B"; return; fi
    local -a units=("B" "KiB" "MiB" "GiB" "TiB")
    local unit_idx=0
    local size=$bytes
    while (( $(echo "$size > 1024" | bc -l) && unit_idx < 4 )); do
        size=$(awk "BEGIN {printf \"%.2f\", $size/1024}")
        ((unit_idx++))
    done
    # Remove trailing .00 if present
    echo "$size${units[$unit_idx]}" | sed 's/\.00//'
}

show_help() {
    echo "Usage: code-compress [OPTIONS] [COMMAND | PATH]"
    echo ""
    echo "Options:"
    echo "  -0..-9         Output directory depth relative to current dir (default: -0)"
    echo "  -o [dir]       Custom output directory"
    echo "  -lfast         Ultra-fast compression (Format: lz4, Ext: .tar.lz4)"
    echo "  -lsm           Small compression (Level 3 - Fast, Ext: .tar.zst)"
    echo "  -lm            Medium compression (Level 9 - Balanced, Default, Ext: .tar.zst)"
    echo "  -lx            Large compression (Level 16 - Strong, Ext: .tar.zst)"
    echo "  -lxx           Extreme compression (Level 19 - Ultra, Ext: .tar.zst)"
    echo "  -l[num]        Custom zstd compression level (e.g., -l12)"
    echo ""
    echo "Commands:"
    echo "  ls [path]      List archives (.tar.zst, .tar.lz4) in path (default: .)"
    echo "  [file].tar.*   Extract the specified archive into a new directory"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Compression:"
    echo "  [path]         Compress the specified directory (use '.' for current dir)"
    echo "                 Creates: {NAME}-{HEX_TIME}[-{REV}].tar.*"
}

# 1. Handle explicit help flags
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# 2. Handle 'ls' command
if [[ "$1" == "ls" ]]; then
    LS_PATH="${2:-.}"
    if [[ ! -d "$LS_PATH" ]]; then
        echo "Error: Directory '$LS_PATH' not found."
        exit 1
    fi
    echo "Listing archives in $LS_PATH..."
    printf "%-45s %-10s %-8s | %-10s %-10s %-12s %-6s\n" "NAME" "DATE" "TIME" "REV" "SIZE" "UNCOMP" "RATIO"
    echo "-----------------------------------------------------------------------------------------------------------------------"

    (
        cd "$LS_PATH" || exit 1
        for file in *.tar.zst *.tar.lz4; do
            [[ -e "$file" ]] || continue

            if [[ "$file" == *.tar.lz4 ]]; then
                ext=".tar.lz4"
                tool="lz4"
            else
                ext=".tar.zst"
                tool="zstd"
            fi

        # Extract name and rev for stats calculation
        # but the user wants the NAME column to be the full file name.
        base=$(basename "$file" "$ext")
        IFS='-' read -ra ADDR <<< "$base"
        len=${#ADDR[@]}
        if [ $len -lt 2 ]; then continue; fi

        last_part=${ADDR[$len-1]}
        prev_part=${ADDR[$len-2]}

        if [[ $prev_part =~ ^[0-9a-f]{8}$ ]] && [ $len -ge 3 ]; then
            hex_ts=$prev_part
            rev=$last_part
        elif [[ $last_part =~ ^[0-9a-f]{8}$ ]]; then
            hex_ts=$last_part
            rev="-"
        else
            hex_ts=$last_part
            rev="-"
        fi

        dec_ts=$((16#$hex_ts))
        date_str=$(date -d "@$dec_ts" +"%y:%m:%d %H:%M" 2>/dev/null || date -r "$dec_ts" +"%y:%m:%d %H:%M" 2>/dev/null || echo "??:??:?? ??:??")

        if [[ "$OSTYPE" == "darwin"* ]]; then
            c_size_bytes=$(stat -f%z "$file" 2>/dev/null || echo 0)
        else
            c_size_bytes=$(stat -c%s "$file" 2>/dev/null || echo 0)
        fi

        if [[ "$tool" == "lz4" ]]; then
            u_size_bytes=$(lz4 -dc "$file" 2>/dev/null | wc -c | awk '{print $1}')
        else
            u_size_bytes=$(zstd -dc "$file" 2>/dev/null | wc -c | awk '{print $1}')
        fi

        c_size_fmt=$(format_bytes "$c_size_bytes")
        u_size_fmt=$(format_bytes "$u_size_bytes")

        if [[ "$u_size_bytes" -gt 0 ]]; then
            ratio=$(awk "BEGIN {printf \"%.2f%%\", ($c_size_bytes/$u_size_bytes)*100}")
        else
            ratio="-"
        fi

        # We pass the full filename as the name field
        echo "$dec_ts|$file|$date_str|$rev|$c_size_fmt|$u_size_fmt|$ratio"
    done
    ) | sort -n | while IFS='|' read -r ts name dstr rev csize usize ratio; do
        [[ -z "$ts" ]] && continue
        yy_mm_dd=$(echo "$dstr" | cut -d' ' -f1)
        hh_mm=$(echo "$dstr" | cut -d' ' -f2)
        printf "%-45s %-10s %-8s | %-10s %-10s %-12s %-6s\n" "$name" "$yy_mm_dd" "$hh_mm" "$rev" "$csize" "$usize" "$ratio"
    done
    exit 0
fi

# 3. Handle extraction
if [[ "$1" == *.tar.zst || "$1" == *.tar.lz4 ]]; then
    if [[ -f "$1" ]]; then
        if [[ "$1" == *.tar.lz4 ]]; then
            TARGET_DIR=$(basename "$1" .tar.lz4)
            echo "Extracting $1 to $TARGET_DIR..."
            mkdir -p "$TARGET_DIR"
            lz4 -dc "$1" | tar -xf - -C "$TARGET_DIR"
        else
            TARGET_DIR=$(basename "$1" .tar.zst)
            echo "Extracting $1 to $TARGET_DIR..."
            mkdir -p "$TARGET_DIR"
            zstd -d -c "$1" | tar -xf - -C "$TARGET_DIR"
        fi
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

# 4. Handle Compression
BACK_LEVELS=0
CUSTOM_OUT_DIR=""
COMPRESSION_LEVEL="-9"
FORMAT="zstd"
FILE_EXT=".tar.zst"
THREADS="-T0"

while [[ "$1" == -* ]]; do
    case "$1" in
        -[0-9])
            BACK_LEVELS=${1#-}
            shift
            ;;
        -o)
            CUSTOM_OUT_DIR="$2"
            shift 2
            ;;
        -lfast)
            COMPRESSION_LEVEL="--fast=1"
            FORMAT="lz4"
            FILE_EXT=".tar.lz4"
            shift
            ;;
        -lsm)
            COMPRESSION_LEVEL="-3"
            shift
            ;;
        -lm)
            COMPRESSION_LEVEL="-9"
            shift
            ;;
        -lx)
            COMPRESSION_LEVEL="-16"
            shift
            ;;
        -lxx)
            COMPRESSION_LEVEL="-19"
            shift
            ;;
        -l[0-9]*)
            level_num=${1#-l}
            COMPRESSION_LEVEL="-$level_num"
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [[ -z "$1" && $BACK_LEVELS -eq 0 && -z "$CUSTOM_OUT_DIR" && "$COMPRESSION_LEVEL" == "-9" && -t 0 ]]; then
    show_help
    exit 0
fi

TARGET_PATH="${1:-.}"
if [[ ! -d "$TARGET_PATH" ]]; then
    echo "Error: Target path '$TARGET_PATH' is not a directory."
    exit 1
fi

HEX_TIME=$(printf '%x' $(date +%s))
EXCLUDES=("node_modules" "bin" "build" ".cache" "dist" "target" ".git" "*.o" "*.pyc")
GIT_EXCLUDES=()
for item in "${EXCLUDES[@]}"; do
    GIT_EXCLUDES+=(":(exclude)$item")
done

if [[ -n "$CUSTOM_OUT_DIR" ]]; then
    OUT_DIR="$CUSTOM_OUT_DIR"
else
    OUT_DIR="${PWD}"
    for ((i=0; i<BACK_LEVELS; i++)); do
        OUT_DIR="${OUT_DIR}/.."
    done
fi

(
    mkdir -p "$OUT_DIR" 2>/dev/null
    ABS_OUT_DIR=$(cd "$OUT_DIR" && pwd)
    cd "$TARGET_PATH" || exit 1
    echo "Checking environment in $(pwd)..."

    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
        SHORT_HASH=$(git rev-parse --short HEAD)
        OUT_FILE="${ABS_OUT_DIR}/${REPO_NAME}-${HEX_TIME}-${SHORT_HASH}${FILE_EXT}"
        echo "Detected Git repository: $REPO_NAME ($SHORT_HASH). Using 'git archive'..."
        if [[ "$FORMAT" == "lz4" ]]; then
            git archive --format=tar HEAD . "${GIT_EXCLUDES[@]}" | lz4 $COMPRESSION_LEVEL - "$OUT_FILE"
        else
            git archive --format=tar HEAD . "${GIT_EXCLUDES[@]}" | zstd -f $THREADS $COMPRESSION_LEVEL -o "$OUT_FILE"
        fi
    else
        DIR_NAME=$(basename "$(pwd)")
        OUT_FILE="${ABS_OUT_DIR}/${DIR_NAME}-${HEX_TIME}${FILE_EXT}"
        echo "Not a Git repository. Falling back to rsync + tar..."
        RSYNC_EXCLUDES=()
        for item in "${EXCLUDES[@]}"; do
            RSYNC_EXCLUDES+=("--exclude=$item")
        done
        if [[ "$FORMAT" == "lz4" ]]; then
            rsync -a --filter=':- .gitignore' "${RSYNC_EXCLUDES[@]}" --dry-run ./ ./DUMMY_DEST/ --out-format="###%n" | \
            grep "^###" | sed "s/^###//" | tar -cf - --no-recursion -T - | lz4 $COMPRESSION_LEVEL - "$OUT_FILE"
        else
            rsync -a --filter=':- .gitignore' "${RSYNC_EXCLUDES[@]}" --dry-run ./ ./DUMMY_DEST/ --out-format="###%n" | \
            grep "^###" | sed "s/^###//" | tar -cf - --no-recursion -T - | zstd -f $THREADS $COMPRESSION_LEVEL -o "$OUT_FILE"
        fi
    fi

    if [ $? -eq 0 ]; then
        echo "---"
        echo "Success! Archive created at: $OUT_FILE"
        du -h "$OUT_FILE"
    else
        echo "Error: Compression failed."
        exit 1
    fi
)
