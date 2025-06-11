#!/bin/bash
#
# Terminal Command Completion Wrapper
# Ensures commands complete properly and provide clear completion signals
#

set -e

SCRIPT_NAME="$1"
shift  # Remove script name from arguments

if [ -z "$SCRIPT_NAME" ]; then
    echo "Usage: $0 <script_or_command> [args...]"
    echo ""
    echo "Examples:"
    echo "  $0 ./scripts/auto-fix.sh"
    echo "  $0 bash tests/scripts/test-pipeline.sh"
    echo "  $0 make test"
    exit 1
fi

echo "🚀 Running: $SCRIPT_NAME $*"
echo "⏱️  Started at: $(date)"
echo ""

# Track execution time
START_TIME=$(date +%s)

# Function to handle completion
completion_handler() {
    local exit_code=$1
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    
    echo ""
    echo "================================"
    if [ $exit_code -eq 0 ]; then
        echo "✅ EXECUTION COMPLETED SUCCESSFULLY"
    else
        echo "❌ EXECUTION FAILED (Exit code: $exit_code)"
    fi
    echo "⏱️  Duration: ${duration}s"
    echo "🕐 Finished at: $(date)"
    echo "================================"
    echo ""
    
    # Force output flush
    exec 1>&1
    exec 2>&2
    sync
    
    # Signal completion for automated detection
    echo "COMPLETION_SIGNAL_$(date +%s)" >&2
    
    exit $exit_code
}

# Set up trap for completion handling
trap 'completion_handler $?' EXIT

# Execute the command with all arguments
if [ -x "$SCRIPT_NAME" ]; then
    # Executable script
    "$SCRIPT_NAME" "$@"
elif command -v "$SCRIPT_NAME" >/dev/null 2>&1; then
    # Command in PATH
    "$SCRIPT_NAME" "$@"
else
    # Try to execute as shell script
    bash "$SCRIPT_NAME" "$@"
fi
