#!/bin/bash

# Script to generate documentation for Lua modules
# Now uses the standalone MediaWiki documentation generator

# Change to script directory
cd "$(dirname "$0")"

# Check if standalone generator is available
if [ -f "./generate-docs-standalone.sh" ]; then
    echo "Using standalone MediaWiki documentation generator..."
    bash generate-docs-standalone.sh "$@"
else
    echo "Falling back to legacy unified generator..."
    lua generate-docs-unified.lua "$@"
fi

# Output status
if [ $? -eq 0 ]; then
    echo "Documentation generation completed successfully!"
    echo "Documentation files can be found in src/module-docs/"
else
    echo "Error: Documentation generation failed!"
    exit 1
fi