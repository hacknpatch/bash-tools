# Bash Tools

![Cross-Distro Tests](https://github.com/hacknpatch/bash-tools/actions/workflows/test.yml/badge.svg)

A collection of custom bash scripts and a dynamic loader to make them available in your CLI.

## Setup

To use these tools, add the following line to your `~/.bashrc`:

```bash
. "$HOME/bash-tools/load.sh"
```

The `load.sh` script automatically scans subdirectories within `~/bash-tools/`, finds `.sh` files, and creates aliases for them without the `.sh` extension (skipping `test.sh`).

## Tools

### `code-compress`
A high-performance compression and extraction utility supporting `zstd` and `lz4`.

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

## Testing

A comprehensive test suite is included:
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
