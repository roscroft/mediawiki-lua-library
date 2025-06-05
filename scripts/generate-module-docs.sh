#!/bin/bash

# Script to generate documentation for Lua modules

# Change to script directory
cd "$(dirname "$0")"

# Check for LuaFileSystem
if ! luarocks list | grep -q "luafilesystem"; then
    echo "Installing LuaFileSystem..."
    luarocks install luafilesystem
fi

# Run the documentation generator
echo "Running documentation generator..."
# Pass all arguments from shell script to lua script
lua generate-docs.lua "$@"

# Output status
if [ $? -eq 0 ]; then
    echo "Documentation generation completed successfully!"
    echo "Documentation files can be found in src/module-docs/"
else
    echo "Error: Documentation generation failed!"
    exit 1
fi