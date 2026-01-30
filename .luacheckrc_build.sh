#!/bin/sh
set -e

cd "$(dirname "$0")"

luacheckrc="./.luacheckrc"

# Check if script dependencies are installed
if ! command -v luacheck >/dev/null 2>&1; then
    echo "Error: 'luacheck' not found. Install it with:"
    echo "  luarocks install luacheck"
    exit 1
fi

# Read .luacheckrc up to the read_globals line
temp_file=$(mktemp)
sed '/read_globals/,$d' "$luacheckrc" > "$temp_file"

# Run luacheck and extract undefined variables
echo "Running luacheck to find undefined globals..."
undefined_vars=$(luacheck . 2>&1 | \
    grep -oP "accessing undefined variable '\K[^']+" | \
    sort -u || true)

# If no undefined variables found, just restore original
if [ -z "$undefined_vars" ]; then
    echo "No undefined variables found."
    mv "$temp_file" "$luacheckrc"
    exit 0
fi

# Write the new .luacheckrc with sorted globals
{
    cat "$temp_file"
    echo ""
    echo "read_globals = {"
    echo "$undefined_vars" | while IFS= read -r var; do
        printf '\t"%s",\n' "$var"
    done
    echo "}"
} > "$luacheckrc"

rm -f "$temp_file"

echo "Updated $luacheckrc with $(echo "$undefined_vars" | wc -l) globals"