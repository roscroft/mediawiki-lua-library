# GitHub Copilot Business Rules & Context

## Project Context
- **Project**: MediaWiki Lua Module Library
- **Purpose**: Functional programming utilities for MediaWiki
- **Language**: Lua 5.1 (MediaWiki compatible)

## File Creation Safety & Validation Rules

### **CRITICAL: File Creation Validation**
After creating ANY new file, **ALWAYS** perform these validation steps:

1. **Immediate Size Check**
   ```bash
   ls -la path/to/new-file
   ```
   - If file shows 0 bytes, **STOP** and recreate using alternative method
   - Alert user if empty file detected

2. **Content Verification**
   ```bash
   head -5 path/to/new-file
   ```
   - Verify file contains expected content
   - Check for proper file headers/shebang lines

3. **Permission Verification** (for executable files)
   ```bash
   ls -la path/to/script.sh
   chmod +x path/to/script.sh  # If needed
   ```

### **File Creation Strategy by Type**

#### **Small Files (< 1KB)**
- Use `create_file` tool directly
- Always validate immediately after creation

#### **Medium Files (1KB - 10KB)**
- Use `create_file` for basic structure
- Use `insert_edit_into_file` to add content in sections
- Validate after each major addition

#### **Large Files (> 10KB)**
- Create basic file structure first
- Build content incrementally using `insert_edit_into_file`
- Consider breaking into multiple smaller files
- Validate frequently during creation

#### **Scripts and Executables**
- Create with basic shebang first
- Add functionality in logical sections
- Test execution permissions immediately
- Verify script runs without errors

### **Alternative Creation Methods**
If `create_file` fails or creates empty files:

#### **Method 1: Terminal-based Creation**
```bash
cat > filename.ext << 'EOF'
file content here
EOF
```

#### **Method 2: Echo-based Creation**
```bash
echo "#!/bin/bash" > script.sh
echo "# Script description" >> script.sh
# Continue building file line by line
```

#### **Method 3: Incremental Building**
```bash
touch filename.ext  # Create empty file
# Use insert_edit_into_file to add all content
```

### **Mandatory Validation Checklist**
For EVERY file creation operation:

- [ ] File exists and has size > 0 bytes
- [ ] File contains expected initial content
- [ ] File has correct permissions (executable if needed)  
- [ ] File syntax is valid (for scripts/code)
- [ ] File follows project naming conventions
- [ ] File location follows project structure rules

### **Error Recovery Protocol**
If file creation fails:

1. **Detect**: Use `ls -la` to identify 0-byte files
2. **Report**: Alert user to empty file issue
3. **Recover**: 
   - Delete empty file: `rm empty-file`
   - Recreate using alternative method
   - Validate new file has content
4. **Prevent**: Use different creation strategy for similar files

### **Quality Assurance Steps**
Before completing any file creation task:

1. **Final Verification**
   ```bash
   find . -name "*.sh" -o -name "*.md" -o -name "*.lua" -size 0
   ```
   - Should return no results (no empty files)

2. **Syntax Validation** (language-specific)
   ```bash
   # For shell scripts
   bash -n script.sh
   
   # For Lua files  
   lua -c module.lua
   
   # For markdown
   markdownlint file.md
   ```

3. **Functional Testing**
   ```bash
   # For scripts
   ./script.sh --help  # Should not error
   
   # For modules
   lua -e "require('module')"  # Should load successfully
   ```

## Documentation Rules
1. **Always append to existing files** in docs/ directory
2. **Development notes** go to `docs/development-history.md`
3. **Never create new markdown files** in root directory
4. **Use established file structure** in docs/

## Code Standards
- Follow functional programming principles
- Use JSDoc-style type annotations
- Maintain backward compatibility
- Include comprehensive error handling

## Security Requirements
- Never commit secrets or passwords
- Use environment variables for configuration
- Template files for sensitive configurations
- Follow least privilege principle

## File Organization
- Source code: `src/modules/` (authoritative source files)
- Documentation: `docs/`
- Tests: `tests/`
- Scripts: `scripts/`
- Build artifacts: `build/modules/` (symlinks only - DO NOT EDIT)

## Development Rules
- **ALWAYS edit files in `src/modules/`** - these are the authoritative source files
- **NEVER edit files in `build/modules/`** - these are build artifacts (symlinks)
- Use `src/modules/` for all code changes and fixes
- `build/modules/` is automatically generated via symlinks for MediaWiki compatibility
- Do not apply CodeStandards.lua integrations unless specifically requested 

### **File Operation Best Practices**

#### **Before Any File Operation**
1. **Backup Critical Files** (if modifying existing)
   ```bash
   cp important-file.ext important-file.ext.backup
   ```

2. **Check File Status**
   ```bash
   git status  # Check for uncommitted changes
   ls -la path/to/file  # Verify current state
   ```

#### **During File Operations**
1. **Use Atomic Operations** - Complete one file fully before starting another
2. **Validate Incrementally** - Check file state after each major edit
3. **Preserve File Metadata** - Maintain permissions, timestamps when possible

#### **After File Operations**
1. **Comprehensive Validation** - Size, content, permissions, syntax
2. **Test Functionality** - Ensure files work as intended
3. **Document Changes** - Update relevant documentation if needed

### **Emergency Recovery Procedures**

#### **If File Creation Completely Fails**
```bash
# 1. Clean up any partial files
rm -f failed-file.ext

# 2. Use manual creation method
nano new-file.ext  # Or other editor
# Manually type/paste content

# 3. Verify and set permissions
ls -la new-file.ext
chmod +x new-file.ext  # If executable
```

#### **If File Becomes Corrupted**
```bash
# 1. Check git status
git status

# 2. Restore from git if available
git checkout -- corrupted-file.ext

# 3. Or restore from backup
cp corrupted-file.ext.backup corrupted-file.ext
```

## Git Practices
- **ALWAYS** use 'main' to refer to the main/master/primary/trunk branch. **NEVER** use 'master'.
- **ALWAYS create a new branch for each feature or bugfix**
- **NEVER commit directly to the main branch**
- When feature development is complete, merge the feature branch with a pull request and delete the feature branch if and only if it has been successfully merged
- Use descriptive commit messages
- Keep commits small and focused