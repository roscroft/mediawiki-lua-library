#!/bin/bash
# Development setup script for reorganized structure

set -e

echo "Setting up development environment for reorganized wiki-lua project..."

# Create necessary directories if they don't exist
mkdir -p build/modules build/test-results

# Create symlinks for MediaWiki compatibility in build directory
echo "Creating MediaWiki-compatible symlinks..."
cd build/modules

# Link all source modules with Module: prefix
for file in ../../src/modules/*.lua; do
    if [[ -f "$file" ]]; then
        basename=$(basename "$file" .lua)
        # Convert underscores to spaces for MediaWiki naming
        module_name=$(echo "$basename" | sed 's/_/ /g')
        ln -sf "$file" "Module:$module_name.lua"
        echo "  Module:$module_name.lua -> $file"
    fi
done

cd ../..

# Make scripts executable
chmod +x tests/scripts/*.sh
chmod +x scripts/*.sh 2>/dev/null || true

echo "Development environment setup complete!"
echo ""
echo "New structure:"
echo "  src/modules/     - Core MediaWiki modules"
echo "  src/lib/         - Supporting libraries" 
echo "  src/data/        - Data list modules"
echo "  tests/env/       - Test environments"
echo "  tests/unit/      - Unit tests"
echo "  tests/integration/ - Integration tests"
echo "  tests/scripts/   - Test runners"
echo "  build/modules/   - MediaWiki-compatible symlinks"
echo ""
echo "Key files:"
echo "  tests/env/module-loader.lua - Module loader"
echo "  tests/env/wiki-lua-env.lua - Mock MediaWiki environment"
echo "  tests/scripts/test-pipeline.sh - Test pipeline"
