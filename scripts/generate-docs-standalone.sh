#!/bin/bash
#
# MediaWiki Documentation Generator Wrapper
# Uses the standalone documentation generator to generate MediaWiki module docs
#

set -e

# Configuration
DOCS_GENERATOR_DIR="tools/docs-generator"     # Relative to project root
SOURCE_DIR="src/modules"                      # Relative to project root  
OUTPUT_DIR="src/module-docs"                  # Relative to project root
DEFAULT_STYLE="refactored"
DEFAULT_FORMAT="html"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage information
usage() {
    echo "MediaWiki Documentation Generator Wrapper"
    echo ""
    echo "Usage: $0 [options] [module_name]"
    echo ""
    echo "Options:"
    echo "  --style=STYLE      Documentation style: elegant, functional, refactored, ultimate"
    echo "                     (default: $DEFAULT_STYLE)"
    echo "  --generator=TYPE   Generator type: unified, simple (default: unified)"
    echo "  --format=FORMAT    Output format: html, markdown, both (default: $DEFAULT_FORMAT)"
    echo "  --output=DIR       Output directory (default: $OUTPUT_DIR)"
    echo "  --verbose          Verbose output"
    echo "  --help, -h         Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                           # Generate all modules with default settings"
    echo "  $0 Array                     # Generate Array module only"
    echo "  $0 --style=elegant           # All modules with elegant style"
    echo "  $0 --generator=simple Array  # Use simple generator for Array"
    echo "  $0 --format=both --verbose   # All modules, both formats, verbose"
    echo ""
    # Force output flush
    sync
}

# Check if docs generator exists
check_docs_generator() {
    if [ ! -d "$DOCS_GENERATOR_DIR" ]; then
        echo -e "${RED}❌ Error: Documentation generator not found at $DOCS_GENERATOR_DIR${NC}"
        echo ""
        echo "The standalone MediaWiki documentation generator is available but not set up as a submodule."
        echo "Current integration uses a direct copy. To use as submodule:"
        echo ""
        echo "1. Remove existing copy:"
        echo "   rm -rf $DOCS_GENERATOR_DIR"
        echo ""
        echo "2. Add as submodule:"
        echo "   git submodule add https://github.com/your-org/mediawiki-lua-docs-generator $DOCS_GENERATOR_DIR"
        echo ""
        return 1
    fi
    
    if [ ! -f "$DOCS_GENERATOR_DIR/bin/generate-docs.lua" ]; then
        echo -e "${RED}❌ Error: Documentation generator executable not found${NC}"
        echo "Expected: $DOCS_GENERATOR_DIR/bin/generate-docs.lua"
        return 1
    fi
    
    return 0
}

# Parse command line arguments
GENERATOR="simple"  # Default to simple generator since it's more reliable
STYLE="$DEFAULT_STYLE"
FORMAT="$DEFAULT_FORMAT"
OUTPUT="$OUTPUT_DIR"
VERBOSE=""
MODULE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            usage
            exit 0
            ;;
        --style=*)
            STYLE="${1#*=}"
            shift
            ;;
        --generator=*)
            GENERATOR="${1#*=}"
            shift
            ;;
        --format=*)
            FORMAT="${1#*=}"
            shift
            ;;
        --output=*)
            OUTPUT="${1#*=}"
            shift
            ;;
        --verbose)
            VERBOSE="--verbose"
            shift
            ;;
        --*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            usage
            exit 1
            ;;
        *)
            MODULE_NAME="$1"
            shift
            ;;
    esac
done

# Main execution
main() {
    echo -e "${BLUE}📚 MediaWiki Documentation Generator${NC}"
    echo ""
    
    # Check prerequisites
    if ! check_docs_generator; then
        echo -e "${RED}❌ Documentation generator not available${NC}"
        exit 1
    fi
    
    # Show configuration
    if [ -n "$VERBOSE" ]; then
        echo -e "${YELLOW}🔧 Configuration:${NC}"
        echo "  Generator: $GENERATOR"
        echo "  Style: $STYLE"
        echo "  Format: $FORMAT"
        echo "  Source: $SOURCE_DIR"
        echo "  Output: $OUTPUT"
        if [ -n "$MODULE_NAME" ]; then
            echo "  Module: $MODULE_NAME"
        fi
        echo ""
    fi
    
    # Build command arguments
    ARGS=""
    ARGS="$ARGS --generator=$GENERATOR"
    ARGS="$ARGS --style=$STYLE"
    ARGS="$ARGS --format=$FORMAT"
    
    # Change to project root (parent of scripts directory)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    cd "$PROJECT_ROOT"
    
    # Now change to docs generator directory and adjust paths
    cd "$DOCS_GENERATOR_DIR"
    
    # Use relative paths from generator directory to project root
    ARGS="$ARGS --source=../../$SOURCE_DIR"
    ARGS="$ARGS --output=../../$OUTPUT"
    
    if [ -n "$VERBOSE" ]; then
        ARGS="$ARGS --verbose"
    fi
    
    if [ -n "$MODULE_NAME" ]; then
        ARGS="$ARGS $MODULE_NAME"
    fi
    
    # Execute documentation generator
    echo -e "${GREEN}🚀 Generating documentation...${NC}"
    
    if lua bin/generate-docs.lua $ARGS; then
        echo ""
        echo -e "${GREEN}✅ Documentation generation completed successfully!${NC}"
        echo -e "${BLUE}📁 Output written to: $OUTPUT${NC}"
    else
        echo ""
        echo -e "${RED}❌ Documentation generation failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"

# Force output flush and completion signal
exec 1>&1
exec 2>&2
echo ""
echo "✅ SCRIPT COMPLETED SUCCESSFULLY"
echo "$(date): Documentation generation finished"
sync
exit 0
