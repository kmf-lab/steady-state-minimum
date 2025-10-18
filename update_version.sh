#!/usr/bin/env bash
# update_version.sh <new_version>   e.g.  ./update_version.sh 0.2.4

set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 <new_version>"; exit 1; }
VERSION=$1
CARGO_TOML="Cargo.toml"
TMP_FILE="${CARGO_TOML}.tmp"

# Step 1: switch to the local path for the pre-publish test
sed 's/^steady_state\s*=\s*".*"/steady_state = { path = "..\/steady-state-stack\/core" }/' \
    "$CARGO_TOML" > "$TMP_FILE"
mv "$TMP_FILE" "$CARGO_TOML"

echo "Testing against ../steady-state-stack/core ..."

if cargo test --quiet; then
    # Step 2: tests passed – update both steady_state and our version
    sed -e "s/^steady_state\s*=.*$/steady_state = \"${VERSION}\"/" \
        -e "s/^version\s*=.*$/version = \"${VERSION}\"/" \
        "$CARGO_TOML" > "$TMP_FILE"
    mv "$TMP_FILE" "$CARGO_TOML"
    echo "Tests passed. steady_state and package version set to ${VERSION} for publishing."
else
    # Step 3: tests failed – leave path in place and add comment
    echo "# FAILED TESTS against ../steady-state-stack/core -- needs manual debugging" >> "$CARGO_TOML"
    echo "Tests failed, Cargo.toml left pointing to local path with debug note."
    exit 1
fi

echo
echo "Final Cargo.toml:"
cat "$CARGO_TOML"
