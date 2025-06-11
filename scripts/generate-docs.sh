#!/bin/bash
#
# Documentation Generator Integration Script
# Manages the external lua-docs-generator as a dependency
#

set -e

DOCS_GENERATOR_REPO="https://github.com/roscroft/lua-docs-generator.git"
DOCS_GENERATOR_DIR="tools/lua-docs-generator"
SOURCE_DIR="src/modules"
OUTPUT_DIR="src/module-docs"

echo "📚 MediaWiki Lua Library - Documentation Generator"
echo "================================================="

# Function to check if docs generator is available
check_docs_generator() {
    if [ -d "$DOCS_GENERATOR_DIR" ]; then
        echo "✅ Documentation generator found at: $DOCS_GENERATOR_DIR"
        return 0
    else
        echo "❌ Documentation generator not found"
        return 1
    fi
}

# Function to install/update docs generator
install_docs_generator() {
    echo "📥 Installing documentation generator..."
    
    if [ -d "$DOCS_GENERATOR_DIR" ]; then
        echo "🔄 Updating existing installation..."
        cd "$DOCS_GENERATOR_DIR"
        git pull origin main
        cd ../..
    else
        echo "🆕 Cloning documentation generator..."
        mkdir -p tools
        git clone "$DOCS_GENERATOR_REPO" "$DOCS_GENERATOR_DIR"
    fi
    
    echo "✅ Documentation generator ready"
}

# Function to generate documentation
generate_docs() {
    local style="${1:-refactored}"
    local module="${2:-}"
    
    if ! check_docs_generator; then
        install_docs_generator
    fi
    
    echo "📖 Generating documentation..."
    echo "  Style: $style"
    echo "  Source: $SOURCE_DIR"
    echo "  Output: $OUTPUT_DIR"
    
    # Ensure output directory exists
    mkdir -p "$OUTPUT_DIR"
    
    # Run the documentation generator
    cd "$DOCS_GENERATOR_DIR"
    
    if [ -n "$module" ]; then
        echo "  Module: $module"
        lua bin/lua-docs-generator --style="$style" --source="../../$SOURCE_DIR" --output="../../$OUTPUT_DIR" --verbose "$module"
    else
        echo "  Modules: All"
        lua bin/lua-docs-generator --style="$style" --source="../../$SOURCE_DIR" --output="../../$OUTPUT_DIR" --verbose --all
    fi
    
    cd ../..
    
    echo "✅ Documentation generation complete"
    echo "📁 Output available in: $OUTPUT_DIR"
}

# Function to show help
show_help() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install                 Install/update the documentation generator"
    echo "  generate [style] [module]  Generate documentation"
    echo "  check                  Check if documentation generator is available"
    echo "  help                   Show this help message"
    echo ""
    echo "Styles:"
    echo "  refactored             Clean, structured output (default)"
    echo "  functional             Functional programming focused"
    echo "  elegant                Minimalist, readable output"
    echo ""
    echo "Examples:"
    echo "  $0 install                    # Install documentation generator"
    echo "  $0 generate                   # Generate all docs with refactored style"
    echo "  $0 generate elegant           # Generate all docs with elegant style"
    echo "  $0 generate refactored Array  # Generate Array module only"
}

# Main command handling
case "${1:-generate}" in
    "install")
        install_docs_generator
        ;;
    "generate")
        generate_docs "${2:-refactored}" "${3:-}"
        ;;
    "check")
        if check_docs_generator; then
            echo "✅ Documentation generator is ready"
        else
            echo "❌ Documentation generator not found. Run: $0 install"
            exit 1
        fi
        ;;
    "help"|"--help"|"-h")
        show_help
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
