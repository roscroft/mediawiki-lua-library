#!/bin/bash
#
# Generate MediaWiki Documentation Script
# Calls the MediaWiki documentation generator with appropriate environment settings
#

set -e

# Script directory detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCS_GENERATOR_DIR="$PROJECT_ROOT/tools/docs-generator"

# Default configuration
USE_LOCAL_ENV="true"
VERBOSE=""
MODULE_NAME=""
OUTPUT_DIR="$PROJECT_ROOT/src/module-docs"
INPUT_DIR="$PROJECT_ROOT/src/modules"

# Function to display help
show_help() {
    echo "MediaWiki Documentation Generator for wiki-lua project"
    echo
    echo "Usage: $0 [options] [module_name]"
    echo
    echo "Options:"
    echo "  --help, -h           Show this help message"
    echo "  --verbose            Enable verbose output"
    echo "  --standalone         Use standalone environment (default: use local)"
    echo "  --output-dir DIR     Output directory (default: src/module-docs)"
    echo "  --input-dir DIR      Input directory (default: src/modules)"
    echo
    echo "Arguments:"
    echo "  module_name          Name of specific module to process (optional)"
    echo
    echo "Examples:"
    echo "  $0                   # Generate all modules"
    echo "  $0 Array             # Generate Array module only"
    echo "  $0 --verbose Array   # Generate Array with verbose output"
    echo "  $0 --standalone      # Use standalone environment"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --verbose)
            VERBOSE="--verbose"
            shift
            ;;
        --standalone)
            USE_LOCAL_ENV="false"
            shift
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --input-dir)
            INPUT_DIR="$2"
            shift 2
            ;;
        --*)
            echo "Error: Unknown option $1"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [[ -z "$MODULE_NAME" ]]; then
                MODULE_NAME="$1"
            else
                echo "Error: Multiple module names specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validation
if [[ ! -d "$DOCS_GENERATOR_DIR" ]]; then
    echo "❌ Error: docs-generator not found at $DOCS_GENERATOR_DIR"
    echo "   Make sure you're running this from the wiki-lua project root"
    exit 1
fi

if [[ ! -f "$DOCS_GENERATOR_DIR/bin/generate-docs-mediawiki.lua" ]]; then
    echo "❌ Error: MediaWiki generator not found"
    echo "   Expected: $DOCS_GENERATOR_DIR/bin/generate-docs-mediawiki.lua"
    exit 1
fi

# Build generator command
GENERATOR_CMD=(
    "lua"
    "$DOCS_GENERATOR_DIR/bin/generate-docs-mediawiki.lua"
)

# Add environment flag
if [[ "$USE_LOCAL_ENV" == "true" ]]; then
    GENERATOR_CMD+=(--use-local-env)
fi

# Add verbose flag
if [[ -n "$VERBOSE" ]]; then
    GENERATOR_CMD+=("$VERBOSE")
fi

# Add directories
GENERATOR_CMD+=(--input-dir "$INPUT_DIR")
GENERATOR_CMD+=(--output-dir "$OUTPUT_DIR")

# Add module name if specified
if [[ -n "$MODULE_NAME" ]]; then
    GENERATOR_CMD+=("$MODULE_NAME")
fi

# Display what we're about to run
if [[ -n "$VERBOSE" ]]; then
    echo "🚀 Running MediaWiki documentation generator"
    echo "   Command: ${GENERATOR_CMD[*]}"
    echo "   Working directory: $DOCS_GENERATOR_DIR"
    echo
fi

# Change to generator directory and run
cd "$DOCS_GENERATOR_DIR"

# Run the generator
"${GENERATOR_CMD[@]}"

# Report results
echo
echo "📝 MediaWiki documentation generation completed"
echo "   Output directory: $OUTPUT_DIR"
if [[ -n "$MODULE_NAME" ]]; then
    echo "   Generated: $OUTPUT_DIR/$MODULE_NAME.wiki"
else
    echo "   Generated: *.wiki files for all modules"
fi
echo "   Format: MediaWiki {{Documentation}} template syntax"
