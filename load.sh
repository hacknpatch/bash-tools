# Determine the directory where this script is located
BASH_TOOLS_ROOT="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# Walk through subdirectories and find .sh files to create aliases
# This looks for .sh files in subdirectories and creates aliases without the extension
while IFS= read -r -d '' script; do
    # Get the basename without the .sh extension
    cmd_name=$(basename "$script" .sh)
    
    # Skip test.sh
    if [[ "$cmd_name" == "test" ]]; then
        continue
    fi
    
    # Create an alias for the script
    alias "$cmd_name"="$script"
done < <(find "$BASH_TOOLS_ROOT" -mindepth 2 -name "*.sh" -type f -print0)
