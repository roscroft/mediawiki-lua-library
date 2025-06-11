#!/bin/bash
#
# Script Completion Enhancement Tool
# Adds proper completion signaling to existing scripts
#

set -e

SCRIPT_FILE="$1"

if [ -z "$SCRIPT_FILE" ]; then
    echo "Usage: $0 <script_file>"
    echo ""
    echo "This tool enhances a script with proper completion signaling."
    exit 1
fi

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "❌ Error: Script file not found: $SCRIPT_FILE"
    exit 1
fi

echo "🔧 Enhancing script completion for: $SCRIPT_FILE"

# Create backup
cp "$SCRIPT_FILE" "${SCRIPT_FILE}.backup"
echo "📋 Backup created: ${SCRIPT_FILE}.backup"

# Check if script already has completion signaling
if grep -q "Script completed successfully\|SCRIPT COMPLETED\|sync" "$SCRIPT_FILE"; then
    echo "ℹ️  Script already appears to have completion signaling"
    echo "   Manual review recommended"
    exit 0
fi

# Add completion signaling before the last exit or at the end
if grep -q "^exit" "$SCRIPT_FILE"; then
    # Insert before last exit
    sed -i '/^exit/i\\necho ""\necho "✅ Script completed successfully!"\necho "🕐 Finished at: $(date)"\n# Force output flush\nexec 1>&1\nexec 2>&2\nsync\necho ""' "$SCRIPT_FILE"
else
    # Add at the end
    cat >> "$SCRIPT_FILE" << 'COMPLETION_CODE'

echo ""
echo "✅ Script completed successfully!"
echo "🕐 Finished at: $(date)"

# Force output flush
exec 1>&1
exec 2>&2
sync
echo ""
COMPLETION_CODE
fi

echo "✅ Enhanced script completion for: $SCRIPT_FILE"
echo "🔄 To restore original: mv ${SCRIPT_FILE}.backup $SCRIPT_FILE"
