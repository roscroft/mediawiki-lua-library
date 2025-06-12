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

## Project-Specific Guidelines & Patterns

### **Wiki Documentation Strategy**
- **Primary Documentation Location**: GitHub Wiki (not docs/ folder)
- **Wiki Content Generation**: Use `scripts/generate-wiki-quick.sh` for creating wiki pages
- **Wiki Deployment**: Use `scripts/deploy-wiki.sh` for publishing to GitHub
- **README Integration**: All wiki links should use absolute GitHub URLs
- **Wiki Page Structure**: Follow established pattern (Home, Getting-Started, Development-Guide, Testing, Security, GitHub-Actions, Project-Status)

### **Script Consolidation Patterns**
- **Unified Scripts**: Prefer consolidated tools over multiple variants
  - `demo-unified.lua` - Interactive demonstrations
  - `generate-docs-unified.lua` - Documentation generation
  - `test-unified.lua` - Comprehensive testing
- **Legacy Script Handling**: Remove one-time-use migration scripts after completion
- **Script Naming**: Use descriptive names with unified- prefix for consolidated tools

### **MediaWiki-Specific Requirements**
- **Lua Version**: Always ensure Lua 5.1 compatibility (MediaWiki requirement)
- **Scribunto Integration**: Test all modules in MediaWiki environment
- **Performance Constraints**: Consider MediaWiki execution time (10s) and memory (50MB) limits
- **Environment Detection**: Use `MediaWikiAutoInit` for automatic environment setup
- **Module Naming**: Follow MediaWiki module naming conventions (Module:Name)

### **4-Stage Testing Pipeline**
Mandatory testing approach for all code changes:
1. **Syntax Validation** - `luacheck` linting and syntax checking
2. **Basic Execution** - Module compilation and unit tests
3. **Mocked Environment** - Docker-based MediaWiki testing
4. **Scribunto Integration** - Full MediaWiki + Scribunto integration
- **Test Command**: `bash tests/scripts/test-pipeline.sh`
- **VS Code Integration**: Use "Run Test Pipeline" task

### **VS Code Integration Patterns**
- **Task-Based Workflow**: Leverage VS Code tasks for common operations
- **Container Management**: Use tasks for starting/stopping MediaWiki containers
- **Performance Dashboard**: Integrate performance monitoring with VS Code
- **Auto-fix Integration**: Use tasks for automated linting and formatting

### **Security & Environment Configuration**
- **Environment Variables**: All sensitive config in `.env` file (gitignored)
- **Template Files**: Use `.env.template` for configuration examples
- **Secret Generation**: Use `openssl rand -hex` for generating secure keys
- **No Hardcoded Secrets**: Never commit passwords or API keys
- **Docker Security**: Use official images, mount only necessary volumes

### **Repository Structure Rules**
- **Source Authority**: `src/modules/` contains authoritative source code
- **Build Artifacts**: `build/modules/` contains symlinks only (DO NOT EDIT)
- **Unified Scripts**: `scripts/` contains consolidated development tools
- **Wiki Content**: `docs/` for generated wiki pages
- **Clean History**: Remove temporary files and completed migration artifacts

### **Performance & Monitoring**
- **Performance Dashboard**: Use `PerformanceDashboard.lua` for monitoring
- **Functional Programming**: Emphasize pure functions and immutability
- **Error Handling**: Use `CodeStandards.lua` patterns consistently
- **Memory Efficiency**: Consider MediaWiki memory constraints in implementation

### **Documentation Standards**
- **JSDoc-Style**: Use JSDoc annotations for function documentation
- **Code Comments**: Explain complex algorithms and MediaWiki-specific logic
- **Wiki Updates**: Update relevant wiki pages when making significant changes
- **Example Code**: Provide practical examples in `examples/` directory

### **Git & Branch Management**
- **Branch Names**: Use descriptive feature/bugfix branch names
- **Main Branch**: Always use 'main' (never 'master')
- **Commit Messages**: Use conventional commit format with clear descriptions
- **Pull Requests**: Fill out PR template completely with testing evidence
- **Linear History**: Maintain clean git history through proper merging

### **CI/CD Integration**
- **GitHub Actions**: All changes must pass 4-stage CI pipeline
- **Automated Testing**: Run tests locally before submitting PRs
- **Release Process**: Use semantic versioning with automated changelog generation
- **Quality Gates**: All linting, security, and test checks must pass

### **Community & Contribution**
- **Contributing Guidelines**: Follow `CONTRIBUTING.md` for all contributions
- **Code Owners**: Respect `.github/CODEOWNERS` for review assignments
- **Issue Templates**: Use provided templates for bug reports and feature requests
- **Professional Standards**: Maintain enterprise-grade code quality and documentation

### **Terminal Command Execution Best Practices**

#### **Command Completion Detection**
To ensure proper command completion detection and avoid hanging terminals:

1. **Explicit Output Flushing**
   ```bash
   # Always end scripts with clear completion signals
   echo "✅ Script completed successfully!"
   echo "Press Enter to continue..." >&2
   ```

2. **Forced Output Flushing**
   ```bash
   # Force flush stdout and stderr
   exec 1>&1  # Force stdout flush
   exec 2>&2  # Force stderr flush
   echo ""    # Final newline
   ```

3. **Background Process Handling**
   ```bash
   # For background processes, use explicit signaling
   nohup long_running_command &
   PID=$!
   echo "Process started with PID: $PID"
   echo "PROCESS_STARTED" # Completion signal
   ```

4. **Exit Code Verification**
   ```bash
   # Always provide explicit exit status
   if [ $? -eq 0 ]; then
       echo "SUCCESS: Command completed"
   else
       echo "ERROR: Command failed with code $?"
   fi
   ```

#### **Script Template for Reliable Completion**
```bash
#!/bin/bash
# Script with reliable completion detection

set -e  # Exit on error

# Your script logic here
main_function() {
    # Script operations
    echo "Performing operations..."
    # ... actual work ...
}

# Cleanup function
cleanup() {
    echo "🧹 Cleanup completed"
}

# Main execution with completion signaling
{
    main_function
    cleanup
    echo ""
    echo "✅ SCRIPT COMPLETED SUCCESSFULLY"
    echo "$(date): Script finished"
} 2>&1 | tee /dev/stderr

# Force final output flush
sync
exit 0
```

#### **Enhanced Script Completion Patterns**
```bash
# Pattern 1: Explicit completion with timestamp
echo "🎉 Operation completed at $(date)"
echo "🔄 Ready for next command"

# Pattern 2: Multi-line completion signal
echo ""
echo "================================"
echo "✅ OPERATION COMPLETE"
echo "================================"
echo ""

# Pattern 3: Status summary
echo "📊 Final Status:"
echo "   ✅ Success: Operation completed"
echo "   📁 Files processed: X"
echo "   ⏱️  Duration: Y seconds"
echo ""
```

#### **VS Code Terminal Integration**
For better VS Code terminal integration:

```bash
# Add to scripts for VS Code task integration
echo "VSCODE_TASK_COMPLETE" >&2  # VS Code completion signal
echo -e "\033]0;Task Complete\007"  # Set terminal title
```

#### **Testing Script Completion**
Create validation for script completion:

```bash
# Test script completion detection
test_script_completion() {
    local script="$1"
    local timeout=30
    
    echo "🧪 Testing script completion: $script"
    
    if timeout $timeout bash "$script"; then
        echo "✅ Script completed within timeout"
        return 0
    else
        echo "❌ Script timed out or failed"
        return 1
    fi
}
```