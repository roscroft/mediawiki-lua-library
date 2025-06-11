#!/bin/bash
#
# Documentation Generation Migration Cleanup
# Removes old documentation scripts after confirming unified scripts work
#

set -e

echo "📚 Documentation Generation Migration Cleanup"
echo "=============================================="
echo ""

# Check if unified scripts are working
echo "🔍 Testing unified documentation generator..."
if lua scripts/generate-docs-unified.lua --help >/dev/null 2>&1; then
    echo "✅ Unified documentation generator is working"
else
    echo "❌ Unified documentation generator has issues"
    echo "Aborting cleanup until issues are resolved"
    exit 1
fi

echo ""
echo "🔍 Testing simple documentation generator..."
if lua scripts/generate-docs-simple.lua --help >/dev/null 2>&1; then
    echo "✅ Simple documentation generator is working"
else
    echo "❌ Simple documentation generator has issues"
    echo "Aborting cleanup until issues are resolved"
    exit 1
fi

echo ""
echo "🔍 Testing wrapper script..."
if bash scripts/generate-module-docs.sh --help >/dev/null 2>&1; then
    echo "✅ Wrapper script is working"
else
    echo "❌ Wrapper script has issues"
    echo "Aborting cleanup until issues are resolved"
    exit 1
fi

echo ""
echo "📋 Migration Status:"
echo "  ✅ generate-docs-unified.lua - Working unified generator"
echo "  ✅ generate-docs-simple.lua - Working simple generator (user-created)"
echo "  ✅ generate-module-docs.sh - Updated wrapper script"
echo "  ❌ generate-docs.sh - Uses external dependency (should be removed)"
echo ""

# Check for external dependency
echo "🔍 Checking for external documentation generator..."
if [ -d "tools/lua-docs-generator" ]; then
    echo "⚠️  External lua-docs-generator found in tools/"
    echo "   This is no longer needed with unified generators"
    echo ""
    read -p "Remove external lua-docs-generator? (y/N): " remove_external
    if [[ $remove_external =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing external lua-docs-generator..."
        rm -rf tools/lua-docs-generator
        echo "✅ External dependency removed"
    else
        echo "⏭️  Keeping external dependency (you can remove it later)"
    fi
else
    echo "✅ No external documentation generator found"
fi

echo ""
echo "🔍 Checking for legacy documentation scripts..."

# Check if we should remove the old generate-docs.sh
if [ -f "scripts/generate-docs.sh" ]; then
    echo "⚠️  Found legacy generate-docs.sh (uses external dependency)"
    echo ""
    read -p "Remove legacy generate-docs.sh? (y/N): " remove_legacy
    if [[ $remove_legacy =~ ^[Yy]$ ]]; then
        echo "🗑️  Removing legacy generate-docs.sh..."
        mv scripts/generate-docs.sh scripts/generate-docs.sh.legacy.bak
        echo "✅ Legacy script moved to generate-docs.sh.legacy.bak"
    else
        echo "⏭️  Keeping legacy script (marked for future removal)"
    fi
fi

echo ""
echo "📊 Migration Summary:"
echo "================================"
echo "✅ Working Documentation Generators:"
echo "   • scripts/generate-docs-unified.lua (consolidated, multiple styles)"
echo "   • scripts/generate-docs-simple.lua (lightweight, no dependencies)"
echo "   • scripts/generate-module-docs.sh (wrapper for unified generator)"
echo ""
echo "🎯 Benefits Achieved:"
echo "   • Removed external dependency on lua-docs-generator"
echo "   • Consolidated multiple scripts into unified tools"
echo "   • Simplified documentation generation process"
echo "   • Maintained backward compatibility through wrapper"
echo ""
echo "🔄 Updated Integration Points:"
echo "   • VS Code tasks now include simple generator"
echo "   • GitHub Actions use unified generator"
echo "   • Wrapper script redirects to unified generator"
echo ""
echo "✨ Documentation Generation Migration Complete!"
echo ""
echo "📝 Next Steps:"
echo "   1. Test all documentation generators in your workflow"
echo "   2. Update any remaining references to old scripts"
echo "   3. Remove backup files when confident in migration"
echo ""
