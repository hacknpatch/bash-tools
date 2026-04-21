# Bash Tools

A collection of custom bash scripts and a dynamic loader to make them available in your CLI.

## Setup

To use these tools, add the following line to your `~/.bashrc`:

```bash
. "$HOME/bash-tools/load.sh"
```
or to be safe:
```
if [ -r "$HOME/bash-tools/load.sh" ]; then
    . "$HOME/bash-tools/load.sh"
fi
```

The `load.sh` script automatically scans subdirectories within `~/bash-tools/`, finds `.sh` files, and creates aliases for them without the `.sh` extension.

## Tools

### `code-zstd`
A high-performance compression and extraction utility using `zstd`.

#### Compression
Run `code-zstd` inside any directory to create a compressed tarball (`.tar.zst`) in the parent directory.
- **In a Git repo**: Uses `git archive` to respect your repository's state. The filename format is `{repo-name}-{timestamp}.tar.zst`.
- **In a non-Git directory**: Uses `rsync` and `tar`, respecting your `.gitignore` if present. The filename format is `{folder-name}-{timestamp}.tar.zst`.

#### Extraction
To extract a supported archive into a new directory in your current path:
```bash
code-zstd filename-20260422-105501.tar.zst
```
This will create a directory named `filename-20260422-105501/` and extract the contents into it.
