#!/bin/bash

# Script to generate documentation for Lua modules
# Wrapper for the unified documentation generator

# Change to script directory
cd "$(dirname "$0")"

# Run the unified documentation generator
echo "Running unified documentation generator..."
# Pass all arguments from shell script to lua script
lua generate-docs-unified.lua "$@"

# Output status
if [ $? -eq 0 ]; then
    echo "Documentation generation completed successfully!"
    echo "Documentation files can be found in src/module-docs/"
else
    echo "Error: Documentation generation failed!"
    exit 1
fi