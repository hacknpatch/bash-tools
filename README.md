# Bash Tools

A collection of custom bash scripts and a dynamic loader to make them available in your CLI.

## Setup

To use these tools, add the following line to your `~/.bashrc`:

```bash
. "$HOME/bash-tools/load.sh"
```

The `load.sh` script automatically scans subdirectories within `~/bash-tools/`, finds `.sh` files, and creates aliases for them without the `.sh` extension.

## Tools

### `code-compress`
A high-performance compression and extraction utility using `zstd`.

#### Compression
To compress a directory, provide the path as the last argument (defaults to `.`):
```bash
code-compress .
# OR
code-compress ./some-folder
```
The archive will be created in your **current working directory**.
Archives use a **Hexadecimal Unix Timestamp** at the start of the filename to ensure they are always sorted chronologically by `ls`.

- **In a Git repo**: Uses `git archive` to respect your repository's state. The filename format is `{hex-timestamp}-{repo-name}-{short-hash}.tar.zst`.
- **In a non-Git directory**: Uses `rsync` and `tar`, respecting your `.gitignore` if present. The filename format is `{hex-timestamp}-{folder-name}.tar.zst`.

#### Listing
To list all compressed archives in your current directory:
```bash
code-compress ls
```
This will display the directory/repository name, the date and time of creation (decoded from the hex timestamp), the revision hash (if applicable), the compressed size, the uncompressed size, and the compression ratio.

#### Extraction
To extract a supported archive into a new directory in your current path:
```bash
code-compress 69fe4595-filename.tar.zst
```
This will create a directory named `69fe4595-filename/` and extract the contents into it.
