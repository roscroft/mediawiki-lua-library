#!/bin/bash

set -e

echo "🔧 Running automatic fixes for MediaWiki Lua Project..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fix MD040 - Add language to fenced code blocks
fix_md040() {
    local file="$1"
    echo "  Fixing MD040 in $file..."
    
    # Use Python script for accurate MD040 fixing
    python3 "${BASH_SOURCE%/*}/fix-md040.py" "$file" > /dev/null 2>&1
    
    # Check if the fix was successful
    if [ $? -eq 0 ]; then
        echo "    ✓ MD040 fixes applied"
    else
        echo "    ✗ Failed to fix MD040"
    fi
}

# Fix trailing whitespace in Lua files
fix_lua_whitespace() {
    local file="$1"
    echo "  Removing trailing whitespace from $file..."
    
    # Check if file has trailing whitespace
    if grep -q '[[:space:]]$' "$file"; then
        # Remove trailing whitespace
        sed -i 's/[[:space:]]*$//' "$file"
        echo "    ✓ Trailing whitespace removed"
    else
        echo "    ✓ No trailing whitespace found"
    fi
}

# Fix Lua files
echo -e "${YELLOW}Processing Lua files...${NC}"

# Remove trailing whitespace from all Lua files
echo "Removing trailing whitespace from Lua files..."
for lua_file in src/modules/*.lua src/data/*.lua tests/*.lua tests/**/*.lua examples/*.lua; do
    if [ -f "$lua_file" ]; then
        fix_lua_whitespace "$lua_file"
    fi
done

# Run luacheck for linting
if command_exists luacheck; then
    echo "Running luacheck on src/modules/"
    luacheck src/modules/*.lua --formatter plain || echo -e "${RED}Lua linting issues found${NC}"
else
    echo "luacheck not installed - skipping Lua linting"
fi

# Fix Markdown files
echo -e "${YELLOW}Formatting Markdown files...${NC}"

# First, fix MD040 issues in all markdown files
echo "Fixing MD040 (fenced code language) issues..."
for md_file in docs/*.md *.md; do
    if [ -f "$md_file" ]; then
        # Check if file has MD040 issues before fixing
        if grep -q '^```[[:space:]]*$' "$md_file"; then
            fix_md040 "$md_file"
        fi
    fi
done

# Then run standard markdown formatting
if command_exists markdownlint; then
    echo "Formatting markdown files in docs/ and root"
    markdownlint docs/*.md *.md --fix --config .markdownlint.json 2>/dev/null || echo "Some markdown issues couldn't be auto-fixed"
    echo -e "${GREEN}Markdown formatting complete${NC}"
else
    echo "markdownlint not installed - run 'npm install' to install dependencies"
fi

# Validate project structure
echo -e "${YELLOW}Validating project structure...${NC}"
required_dirs=("src/modules" "docs" "tests" "scripts")
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo -e "${RED}Missing required directory: $dir${NC}"
    else
        echo -e "${GREEN}✓ $dir${NC}"
    fi
done

# Check for security issues
echo -e "${YELLOW}Security check...${NC}"
if [ -f ".env" ] && ! grep -q "^\.env$" .gitignore; then
    echo -e "${RED}Warning: .env file exists but not in .gitignore${NC}"
fi

# Final markdown validation
echo -e "${YELLOW}Final markdown validation...${NC}"
if command_exists markdownlint; then
    echo "Running final markdownlint check..."
    markdownlint docs/*.md *.md --config .markdownlint.json 2>/dev/null || echo "Some markdown issues remain"
fi

echo -e "${GREEN}🎉 Auto-fix complete!${NC}"