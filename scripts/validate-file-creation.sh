#!/bin/bash
#
# File Creation Validation Script
# Tests file creation and validates against empty file issues
#

echo "🔍 File Creation Validation Test"
echo "================================="

# Test file creation
TEST_FILE="test-creation.tmp"

echo "📝 Testing file creation..."
echo "Hello, World!" > "$TEST_FILE"

# Validate file
echo "🔍 Validating file..."
if [ -f "$TEST_FILE" ]; then
    SIZE=$(stat -c%s "$TEST_FILE" 2>/dev/null || wc -c < "$TEST_FILE")
    echo "✅ File exists"
    echo "📏 File size: $SIZE bytes"
    
    if [ "$SIZE" -gt 0 ]; then
        echo "✅ File has content"
        echo "📄 Content preview:"
        head -3 "$TEST_FILE" | sed 's/^/   /'
    else
        echo "❌ File is empty!"
        exit 1
    fi
else
    echo "❌ File creation failed!"
    exit 1
fi

# Cleanup
rm -f "$TEST_FILE"
echo "🧹 Cleanup complete"
echo "✅ File creation validation passed!"
