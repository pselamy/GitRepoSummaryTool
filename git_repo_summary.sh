#!/bin/bash

# Default values
DEFAULT_GIT_REF="main"
DEFAULT_MAX_LINES=10000
DEFAULT_SUMMARY_PATH="$(pwd)/repo_summary.txt"  # Default path in the current directory

# Usage message
usage() {
    echo "Usage: $0 <repository-url> [git-reference] [max-lines] [summary-path]"
    echo "  git-reference defaults to 'main' if not provided"
    echo "  max-lines defaults to 10000 if not provided"
    echo "  summary-path defaults to the current working directory if not provided"
    exit 1
}

# Check for at least one argument
if [ $# -lt 1 ]; then
    usage
fi

# Read arguments
REPO_URL=$1
GIT_REF=${2:-$DEFAULT_GIT_REF}
MAX_LINES=${3:-$DEFAULT_MAX_LINES}
SUMMARY_PATH=${4:-$DEFAULT_SUMMARY_PATH}

# Create a temporary directory
TMP_DIR=$(mktemp -d)
if [ ! -d "$TMP_DIR" ]; then
    echo "Failed to create temporary directory"
    exit 1
fi

# Function to clean up temporary directory
cleanup() {
    rm -rf "$TMP_DIR"
}

# Register cleanup function to be called on script exit
trap cleanup EXIT

# Clone the repository
git clone "$REPO_URL" "$TMP_DIR" --quiet
if [ $? -ne 0 ]; then
    echo "Git clone failed"
    exit 1
fi

cd "$TMP_DIR"

# Checkout the specified reference
git checkout "$GIT_REF" --quiet
if [ $? -ne 0 ]; then
    echo "Git checkout failed"
    exit 1
fi

# Prepare the summary file
touch "$SUMMARY_PATH"

# Determine the maximum number of digits for padding line numbers
MAX_DIGITS=$(find . -type f -exec file --mime {} \; | grep 'utf-8' | cut -d: -f1 | xargs wc -l | awk '{print $1}' | sort -n | tail -n 2 | head -n 1 | wc -L)

# Find all UTF-8 text files with lines up to the specified maximum and summarize them
find . -type f -exec file --mime {} \; | grep 'utf-8' | cut -d: -f1 | while read -r file; do
    LINE_COUNT=$(wc -l < "$file")
    if [ "$LINE_COUNT" -le "$MAX_LINES" ]; then
        echo "# $file" >> "$SUMMARY_PATH"
        awk -v max_digits="$MAX_DIGITS" '{ printf "%0*d|%s\n", max_digits, NR, $0 }' "$file" >> "$SUMMARY_PATH"
        echo "" >> "$SUMMARY_PATH"  # Add an empty line after each file's content
    fi
done

# Output the path to the summary file
echo "Summary file created at: $SUMMARY_PATH"
