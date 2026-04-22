# Bash Tools

![Cross-Distro Tests](https://github.com/hacknpatch/bash-tools/actions/workflows/test.yml/badge.svg)

Bash scripts for general coding task.

- `code-compress` compresses / decompress directories of code ignore any .gitgnore files etc...

## Setup

To use these tools, add the following line to your `~/.bashrc`:

```bash
. "$HOME/bash-tools/load.sh"
```

The `load.sh` script automatically scans subdirectories within `~/bash-tools/`, finds `.sh` files, and creates aliases for them without the `.sh` extension (skipping `test.sh`).

## Tools

### `code-compress`
Compression and extraction utility using / requiring `zstd`.

#### Compression
To compress a directory, provide the path as the last argument (defaults to `.`):
```bash
code-compress [OPTIONS] [PATH]
```

**Options:**
- `-0..-9`: Output directory depth relative to current dir (default: `-0` is current dir, `-1` is parent).
- `-o [dir]`: Specify a custom output directory.
- `-lfast`: Ultra-fast compression using **lz4** format (creates `.tar.lz4`).
- `-lsm`: Small compression (zstd Level 3).
- `-lm`: Medium compression (zstd Level 9 - **Default**).
- `-lx`: Large compression (zstd Level 16).
- `-lxx`: Extreme compression (zstd Level 19).
- `-l[num]`: Custom zstd compression level (e.g., `-l12`).

**Naming Convention:**
Archives use a **Hexadecimal Unix Timestamp** to ensure they are always sorted chronologically by `ls`.
- **In a Git repo**: `{repo-name}-{hex-timestamp}-{short-hash}.tar.*`
- **In a non-Git directory**: `{folder-name}-{hex-timestamp}.tar.*`

#### Listing
To list all supported archives in a directory (defaults to `.`):
```bash
code-compress ls [path]
```
Outputs: `NAME`, `DATE`, `TIME`, `REV`, `SIZE` (compressed), `UNCOMP` (uncompressed), and `RATIO`.

#### Extraction
To extract a supported archive into a new directory in your current path:
```bash
code-compress filename-69fe4595.tar.zst
```
This automatically detects the format (`zstd` or `lz4`) and extracts into a folder named after the archive.

**compress**
```bash
~/bash-tools$ code-compress -o /tmp/ .
Checking environment in /bash-tools...
Detected Git repository: bash-tools (b8a90f6). Using 'git archive'...
/*stdin*\            : 19.94%   (  30.0 KiB =>   5.98 KiB, /tmp/bash-tools-69e81fad-b8a90f6.tar.zst) 
---
Success! Archive created at: /tmp/bash-tools-69e81fad-b8a90f6.tar.zst
8.0K	/tmp/bash-tools-69e81fad-b8a90f6.tar.zst
```

**list**
```bash
~/bash-tools$ code-compress ls /tmp/
Listing archives in /tmp/...
NAME                                          DATE       TIME     | REV        SIZE       UNCOMP       RATIO 
-----------------------------------------------------------------------------------------------------------------------
test_archive-20260422-111104.tar.zst          87:02:04   03:52    | 111104     156B       10KiB        1.52% 
...
demo-69e8121a-12beb2d.tar.zst                 26:04:22   12:11    | 12beb2d    2.47MiB    5.31MiB      46.58%
bash-tools-69e81fad-b8a90f6.tar.zst           26:04:22   13:09    | b8a90f6    5.98KiB    30KiB        19.94%
```

**decompress**
```bash
$ code-compress bash-tools-69e81fad-b8a90f6.tar.zst 
Extracting bash-tools-69e81fad-b8a90f6.tar.zst to bash-tools-69e81fad-b8a90f6...
Success! Extracted to bash-tools-69e81fad-b8a90f6
/tmp$ ls -l
total 44096
drwxrwxr-x 4 gregc gregc    4096 Apr 22 13:11 bash-tools-69e81fad-b8a90f6
```

## Testing

- **Local tests**: Run `./code-compress/test.sh` (creates and cleans up a local `./test` directory).
- **Cross-distro tests**: Run tests against different Linux distributions using Docker:

```bash
# Ubuntu
docker build -t cc-test:ubuntu --build-arg DISTRO=ubuntu:latest -f Dockerfile.test . && docker run --rm cc-test:ubuntu

# Alpine
docker build -t cc-test:alpine --build-arg DISTRO=alpine:latest -f Dockerfile.test . && docker run --rm cc-test:alpine

# Debian
docker build -t cc-test:debian --build-arg DISTRO=debian:stable-slim -f Dockerfile.test . && docker run --rm cc-test:debian

# Fedora
docker build -t cc-test:fedora --build-arg DISTRO=fedora:latest -f Dockerfile.test . && docker run --rm cc-test:fedora
```
