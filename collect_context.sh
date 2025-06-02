#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

output_file="rust_source_summary.md"

# Start with README.md if present
if [ -f README.md ]; then
  cat README.md > "$output_file"
  echo >> "$output_file"
  echo '---' >> "$output_file"
  echo >> "$output_file"
else
  : > "$output_file"
fi

# Project tree
{
  echo '# Rust Source Summary'
  echo
  echo '## Project Structure'
  echo
  echo '```'
  tree -I 'target|.*'
  echo '```'
  echo
} >> "$output_file"

# For each Cargo.toml (including the root one)
while IFS= read -r toml; do
  project_dir=$(dirname "$toml")
  # Find *.rs and *.toml under each project_dir, but skip target/ and hidden dirs
  find "$project_dir" \
    -type f \
    \( -name '*.rs' -o -name '*.toml' \) \
    -not -path '*/target/*' \
    -not -path '*/.*/*' \
    | sort \
    | while IFS= read -r file; do
        ext="${file##*.}"
        case "$ext" in
          rs)   language=rust ;;
          toml) language=toml ;;
          *)    language=text ;;
        esac

        echo "## $file" >> "$output_file"
        echo >> "$output_file"
        echo '```'"$language" >> "$output_file"
        cat "$file" >> "$output_file"
        echo '```' >> "$output_file"
        echo >> "$output_file"
      done
done < <(find . -type f -name Cargo.toml)