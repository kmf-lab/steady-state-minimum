#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

output_file="lesson-00-minimum.md"

# Function to generate directory tree, excluding 'target' and hidden directories
get_directory_tree() {
    local path=$1
    local prefix=$2
    local items=()
    while IFS= read -r -d '' item; do
        items+=("$item")
    done < <(find "$path" -mindepth 1 -maxdepth 1 ! -name 'target' ! -name '.*' -print0)
    local count=${#items[@]}
    for ((i=0; i<count; i++)); do
        local item=${items[$i]}
        local base=$(basename "$item")
        local last=$((i == count - 1))
        local item_prefix
        if [ $last -eq 1 ]; then
            item_prefix='\-- '
        else
            item_prefix='+-- '
        fi
        echo "$prefix$item_prefix$base"
        if [ -d "$item" ]; then
            local new_prefix
            if [ $last -eq 1 ]; then
                new_prefix="$prefix    "
            else
                new_prefix="$prefix|   "
            fi
            get_directory_tree "$item" "$new_prefix"
        fi
    done
}

# Initialize output file, including README.md if it exists
if [ -f README.md ]; then
    cat README.md > "$output_file"
    echo "" >> "$output_file"
    echo "---" >> "$output_file"
    echo "" >> "$output_file"
else
    : > "$output_file"
fi

# Add project structure section
{
    echo '# Lesson 00: Minimum'
    echo ''
    echo '## Project Structure'
    echo ''
    echo '```'
    echo '.'
    get_directory_tree '.' ''
    echo '```'
    echo ''
} >> "$output_file"

# Process each Cargo.toml and associated .rs and .toml files
cargo_tomls=$(find . -type f -name Cargo.toml)
for toml in $cargo_tomls; do
    project_dir=$(dirname "$toml")
    files=$(find "$project_dir" -type f \( -name '*.rs' -o -name '*.toml' \) ! -path '*/target/*' ! -path '*/.*/*' | sort)
    for file in $files; do
        relative_path=$(realpath --relative-to=. "$file")
        ext="${file##*.}"
        # Add file header
        echo "## $relative_path" >> "$output_file"
        echo '' >> "$output_file"
        # Directly echo the code block delimiter based on extension
        case "$ext" in
            rs) echo '```rust' ;;
            toml) echo '```toml' ;;
            *) echo '```text' ;;
        esac >> "$output_file"
        # Append file content and ensure it ends with a newline
        cat "$file" >> "$output_file"
        if [ -s "$file" ] && [ "$(tail -c 1 "$file")" != $'\n' ]; then
            echo >> "$output_file"
        fi
        # Close code block and add spacing
        echo '```' >> "$output_file"
        echo '' >> "$output_file"
    done
done

# Create a .txt copy if the output file is not already a .txt file
if [[ "$output_file" != *.txt ]]; then
    cp "$output_file" "${output_file}.txt"
fi