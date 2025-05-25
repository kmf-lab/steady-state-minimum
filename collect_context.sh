#!/bin/bash

# Define the output file
output_file="rust_source_summery.md"

# Check if README.md exists and initialize the file with its content
if [ -f "README.md" ]; then
    # Start with README.md content
    cat README.md > "$output_file"
    echo "" >> "$output_file"
    echo "---" >> "$output_file"
    echo "" >> "$output_file"
else
    # Initialize empty file if no README
    > "$output_file"
fi

# Add the Rust Source Summary section
echo "# Rust Source Summary" >> "$output_file"
echo "" >> "$output_file"
echo "## Project Structure" >> "$output_file"
echo "" >> "$output_file"
echo '```' >> "$output_file"

# Capture the directory tree, excluding 'target' and hidden directories
tree -I 'target|.*' >> "$output_file"

echo '```' >> "$output_file"
echo "" >> "$output_file"

# Find all Cargo.toml files to identify Rust project folders
find . -type f -name Cargo.toml | while read toml; do
    # Extract the project directory from the Cargo.toml path
    project_dir=$(dirname "$toml")
    # Find all *.toml and *.rs files in the project directory, excluding 'target' and hidden directories
    find "$project_dir" -type d \( -name 'target' -o -name '.*' \) -prune -o -type f \( -name '*.toml' -o -name '*.rs' \) -print | while read file; do
        # Determine the language for syntax highlighting
        case "${file##*.}" in
            rs)
                language="rust"
                ;;
            toml)
                language="toml"
                ;;
            *)
                language="text"
                ;;
        esac

        # Add markdown header for the file
        echo "## $file" >> "$output_file"
        echo "" >> "$output_file"

        # Add the file content in a code block with appropriate language
        echo "\`\`\`$language" >> "$output_file"
        cat "$file" >> "$output_file"
        echo '```' >> "$output_file"
        echo "" >> "$output_file"
    done
done
