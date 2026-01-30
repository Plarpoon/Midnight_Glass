#!/bin/sh
set -e

cd "$(dirname "$0")"

# Check if script dependencies are installed
if ! command -v zip >/dev/null 2>&1; then
    echo "Error: 'zip' package not found. Please install it."
    exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
    echo "Error: 'rsync' package not found. Please install it."
    exit 1
fi

# Get the project name from the directory
name=$(basename "$(pwd)")

# Check if .toc file exists
toc_file="./${name}/${name}.toc"
if [ ! -f "$toc_file" ]; then
    echo "Error: .toc file not found at $toc_file"
    exit 1
fi

# Extract version from .toc file
version=$(grep -oP '(?<=## Version: )[a-zA-Z0-9.-]+' "$toc_file" || true)
if [ -z "$version" ]; then
    echo "Error: Could not find version in .toc file"
    exit 1
fi

echo "Building $name version $version..."

# Create temp directory
temp_dir="./temp"
rm -rf "$temp_dir"
mkdir -p "$temp_dir"

# Copy addon folder excluding unwanted files
rsync -a --exclude='*.doc*' \
         --exclude='*.editorconfig' \
         --exclude='.git*' \
         --exclude='*.luacheck*' \
         --exclude='*.pkg*' \
         --exclude='*.sh' \
         --exclude='*.yml' \
         "./${name}/" "$temp_dir/${name}/"

# Create zip file
output_zip="../${name}-${version}.zip"
cd "$temp_dir"
zip -r -9 "$output_zip" "${name}"
cd ..

rm -rf "$temp_dir"

echo "Created: $output_zip"