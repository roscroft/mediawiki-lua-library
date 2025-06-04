#!/usr/bin/env python3

"""
Fix MD040 - Add language to fenced code blocks (opening blocks only)
This script properly distinguishes between opening and closing code blocks.
"""

import sys
import re
import argparse

def fix_md040_properly(filename):
    """Fix MD040 issues in a markdown file by adding 'plaintext' to opening code blocks without language."""
    
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            lines = f.readlines()
    except IOError as e:
        print(f"Error reading {filename}: {e}")
        return False
    
    inside_code_block = False
    fixes_made = 0
    result_lines = []
    
    print(f"  Analyzing {filename} for MD040 issues...")
    
    for line_num, line in enumerate(lines, 1):
        line_stripped = line.rstrip()
        
        # Check if this line starts with ``` (code fence)
        if re.match(r'^```\s*$', line_stripped):
            if not inside_code_block:
                # This is an opening block without language - add plaintext
                result_lines.append('```plaintext\n')
                print(f"    Line {line_num}: Added 'plaintext' to opening code block")
                fixes_made += 1
                inside_code_block = True
            else:
                # This is a closing block - leave as is
                result_lines.append(line)
                inside_code_block = False
        elif re.match(r'^```[a-zA-Z0-9_+-]+.*$', line_stripped):
            # This is an opening block WITH language - leave as is
            result_lines.append(line)
            inside_code_block = True
        else:
            # Regular line - copy as is
            result_lines.append(line)
    
    if fixes_made > 0:
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                f.writelines(result_lines)
            print(f"    ✓ Fixed {fixes_made} MD040 issues")
            return True
        except IOError as e:
            print(f"Error writing {filename}: {e}")
            return False
    else:
        print("    ✓ No MD040 issues found")
        return True

def main():
    parser = argparse.ArgumentParser(description='Fix MD040 issues in markdown files')
    parser.add_argument('files', nargs='+', help='Markdown files to process')
    
    args = parser.parse_args()
    
    print("🔧 Fixing MD040 issues (fenced code language)...")
    
    success = True
    for filename in args.files:
        print(f"Processing: {filename}")
        if not fix_md040_properly(filename):
            success = False
    
    if success:
        print("🎉 MD040 fixes complete!")
    else:
        print("❌ Some files could not be processed")
        sys.exit(1)

if __name__ == '__main__':
    main()
