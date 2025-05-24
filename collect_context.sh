#!/bin/bash

# Capture the directory tree, excluding 'target' and hidden directories, into rust_source_summary.txt
tree -I 'target|.*' > rust_source_summary.txt

# Find all Cargo.toml files to identify Rust project folders
find . -type f -name Cargo.toml | while read toml; do
    # Extract the project directory from the Cargo.toml path
    project_dir=$(dirname "$toml")
    # Find all *.toml and *.rs files in the project directory, excluding 'target' and hidden directories
    find "$project_dir" -type d \( -name 'target' -o -name '.*' \) -prune -o -type f \( -name '*.toml' -o -name '*.rs' \) -print | while read file; do
        # Append the file path as a header
        echo "File: $file" >> rust_source_summary.txt
        # Append the file's content
        cat "$file" >> rust_source_summary.txt
        # Add an empty line for separation
        echo "" >> rust_source_summary.txt
    done
done