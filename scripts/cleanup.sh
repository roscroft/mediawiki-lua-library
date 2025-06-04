#!/bin/bash
# Cleanup script to remove duplicate files after reorganization

set -e

echo "Cleaning up duplicate files after reorganization..."

# Function to safely remove file if it exists
safe_remove() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "Removing: $file"
        rm "$file"
    fi
}

# Function to safely remove directory if it exists and is empty
safe_remove_dir() {
    local dir="$1"
    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir")" ]]; then
        echo "Removing empty directory: $dir"
        rmdir "$dir"
    fi
}

# Remove duplicate files from root (now in src/)
echo "Removing root duplicates..."
safe_remove "abilitylist.lua"
safe_remove "prayerlist.lua" 
safe_remove "shoplist.lua"
safe_remove "spelllist.lua"
safe_remove "lists.lua"
safe_remove "module-loader.lua"
safe_remove "wiki-lua-env.lua"

# Remove duplicate test scripts (now in tests/scripts/)
echo "Removing duplicate test scripts..."
safe_remove "run-luacheck.sh"
safe_remove "lua-syntax-test.sh"
safe_remove "test-pipeline.sh"
safe_remove "test-module.sh"

# Remove duplicate files in lists/ that are now in src/
echo "Removing lists/ duplicates..."
safe_remove "lists/abilitylist.lua"
safe_remove "lists/prayerlist.lua"
safe_remove "lists/shoplist.lua" 
safe_remove "lists/spelllist.lua"
safe_remove "lists/lists.lua"
safe_remove "lists/funclib.lua"
safe_remove "lists/functools.lua"
safe_remove "lists/paramtest.lua"
safe_remove "lists/libraryUtil.lua"
safe_remove "lists/mw.lua"
safe_remove "lists/errors.lua"

# Remove duplicate test files
safe_remove "lists/test_validation.lua"
safe_remove "lists/test_lists.lua"
safe_remove "lists/test_other_functions.lua"
safe_remove "lists/test_imports.lua"
safe_remove "lists/test_framework.lua"
safe_remove "lists/simple_test.lua"
safe_remove "lists/run_tests.lua"

# Remove debug/temporary files
echo "Removing debug/temporary files..."
safe_remove "lists/debug_table.lua"
safe_remove "lists/debug_build_table.lua"
safe_remove "lists/fix_funclib.lua"
safe_remove "lists/fix_function_order.lua"
safe_remove "lists/funclib_flat.lua"
safe_remove "lists/functools_new.lua"
safe_remove "lists/paramtest_demo.lua"
safe_remove "lists/usage_examples.lua"

# Remove files that are duplicated in lists/debug/
safe_remove "lists/debug/debug_table.lua"
safe_remove "lists/debug/debug_build_table.lua" 
safe_remove "lists/debug/fix_funclib.lua"
safe_remove "lists/debug/fix_function_order.lua"

# Remove duplicate test files in lists/tests/
safe_remove "lists/tests/test_validation.lua"
safe_remove "lists/tests/test_other_functions.lua"
safe_remove "lists/tests/test_imports.lua"
safe_remove "lists/tests/simple_test.lua"
safe_remove "lists/tests/run_tests.lua"
safe_remove "lists/tests/test_framework.lua"
safe_remove "lists/tests/test_lists.lua"
safe_remove "lists/tests/paramtest_demo.lua"

# Remove intermediate/generated files
safe_remove "lists/tests/simple_verification.lua"
safe_remove "lists/tests/final_verification.lua"
safe_remove "lists/tests/test_organization.lua"
safe_remove "lists/tests/run_all_tests.lua"
safe_remove "lists/tests/run-tests.lua"

# Remove old symlinks in lists/ (we have new ones in build/)
echo "Removing old symlinks..."
safe_remove "lists/Module:Array.lua"
safe_remove "lists/Module:Clean image.lua"
safe_remove "lists/Module:Funclib.lua"
safe_remove "lists/Module:Functools.lua"
safe_remove "lists/Module:Lists.lua"
safe_remove "lists/Module:Mw html extension.lua"
safe_remove "lists/Module:Paramtest.lua"

# Remove Module: files from lists/library/ (duplicates)
safe_remove "lists/library/Module:Array.lua"
safe_remove "lists/library/Module:Clean image.lua"
safe_remove "lists/library/Module:Funclib.lua"
safe_remove "lists/library/Module:Functools.lua"
safe_remove "lists/library/Module:Lists.lua"
safe_remove "lists/library/Module:Mw html extension.lua"
safe_remove "lists/library/Module:Paramtest.lua"

# Keep the canonical files in lists/library/ for now as they may have fixes
echo "Keeping canonical files in lists/library/ for reference..."

# Remove empty directories
echo "Removing empty directories..."
safe_remove_dir "lists/debug"
# Don't remove lists/tests yet as it may have useful files
# Don't remove lists/library yet as it has the canonical versions

# Remove old documentation files
echo "Removing old documentation (moved to docs/)..."
safe_remove "usage.md"

echo ""
echo "Cleanup complete! Summary of new structure:"
echo "  ✓ Source files organized in src/"
echo "  ✓ Tests organized in tests/"
echo "  ✓ Documentation in docs/"
echo "  ✓ Build artifacts in build/"
echo "  ✓ Duplicates removed"
echo ""
echo "Remaining files in lists/library/ are kept as canonical references."
echo "Run 'find lists/ -name \"*.lua\" | wc -l' to see remaining files."
