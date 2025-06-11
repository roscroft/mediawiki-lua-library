#!/bin/bash
# 
# MediaWiki Lua Documentation Generator Wrapper
# Uses the standalone documentation generator as a submodule
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCS_GENERATOR="$REPO_ROOT/tools/docs-generator"
SOURCE_DIR="$REPO_ROOT/src/modules"
OUTPUT_DIR="$REPO_ROOT/src/module-docs"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if docs generator exists
if [ ! -f "$DOCS_GENERATOR/bin/generate-docs.lua" ]; then
    print_error "Documentation generator not found at $DOCS_GENERATOR"
    print_info "Please ensure the docs-generator submodule is properly initialized"
    exit 1
fi

# Default values
VERBOSE=""
MODULE=""
FORMAT="html"
STYLE="elegant"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --module)
            MODULE="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --style)
            STYLE="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE="--verbose"
            shift
            ;;
        --help|-h)
            echo "MediaWiki Lua Documentation Generator"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --module MODULE   Generate docs for specific module only"
            echo "  --format FORMAT   Output format: html|markdown (default: html)"
            echo "  --style STYLE     Documentation style (default: elegant)"
            echo "  --verbose, -v     Verbose output"
            echo "  --help, -h        Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                               # Generate all modules"
            echo "  $0 --module Array                # Generate Array module only"
            echo "  $0 --format markdown --verbose   # Generate markdown with verbose output"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Print configuration
print_info "MediaWiki Lua Documentation Generator"
print_info "Using standalone docs generator at: $DOCS_GENERATOR"
print_info "Source directory: $SOURCE_DIR"
print_info "Output directory: $OUTPUT_DIR"
print_info "Format: $FORMAT"

if [ -n "$MODULE" ]; then
    print_info "Generating documentation for module: $MODULE"
else
    print_info "Generating documentation for all modules"
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Generate documentation
print_info "Running documentation generator..."

# Change to docs generator directory
cd "$DOCS_GENERATOR"

if [ -n "$MODULE" ]; then
    # Generate for specific module
    MODULE_FILE="$SOURCE_DIR/Module:$MODULE.lua"
    if [ ! -f "$MODULE_FILE" ]; then
        print_error "Module file not found: $MODULE_FILE"
        exit 1
    fi
    
    # Create temporary directory with just this module
    TEMP_DIR="/tmp/lua-docs-single-module-$$"
    mkdir -p "$TEMP_DIR"
    cp "$MODULE_FILE" "$TEMP_DIR/"
    
    lua bin/generate-docs.lua \
        --input="$TEMP_DIR" \
        --output="$OUTPUT_DIR" \
        --format="$FORMAT" \
        $VERBOSE
    
    # Cleanup
    rm -rf "$TEMP_DIR"
else
    # Generate for all modules
    lua bin/generate-docs.lua \
        --input="$SOURCE_DIR" \
        --output="$OUTPUT_DIR" \
        --format="$FORMAT" \
        $VERBOSE
fi

if [ $? -eq 0 ]; then
    print_success "Documentation generation completed successfully!"
    print_info "Documentation available at: $OUTPUT_DIR"
    
    # List generated files
    if [ "$VERBOSE" = "--verbose" ]; then
        print_info "Generated files:"
        find "$OUTPUT_DIR" -name "*.html" -o -name "*.md" | sort | while read file; do
            echo "  📄 $(basename "$file")"
        done
    fi
else
    print_error "Documentation generation failed!"
    exit 1
fi
