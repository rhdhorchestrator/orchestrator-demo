#!/bin/bash

MAX_SIZE=262144  # 256 KB (max size allowed for metadata annotations)
FILE=$1

# Get file size
FILE_SIZE=$(wc -c < "$FILE")

if [ "$FILE_SIZE" -le "$MAX_SIZE" ]; then
    echo "ConfigMap is within size limits. No splitting needed."
    exit 0
fi

# Split file into multiple parts
echo "ConfigMap is too large, splitting into smaller parts..."

SPLIT_DIR="split_configmaps"
mkdir -p "$SPLIT_DIR"

# Split the original file into smaller files
split -b $MAX_SIZE "$FILE" "$SPLIT_DIR/configmap_part_"

# Apply each of the split files
for split_file in "$SPLIT_DIR"/*; do
    kubectl apply -f "$split_file"
    echo "Applied $split_file"
done
