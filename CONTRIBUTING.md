# Contributing to MediaWiki Lua Module Library

Welcome to the MediaWiki Lua Module Library! We appreciate your interest in contributing. This document outlines our contribution process and guidelines.

## 🚀 Quick Start for Contributors

### 1. Fork and Clone
```bash
# Fork the repository on GitHub
git clone https://github.com/YOUR_USERNAME/mediawiki-lua-library.git
cd mediawiki-lua-library
```

### 2. Set Up Development Environment
```bash
# Copy environment template
cp .env.template .env
# Edit .env with your configuration

# Start development environment
make setup
make test  # Verify everything works
```

### 3. Create Feature Branch
```bash
# Create and switch to feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... edit files ...

# Test your changes
make test
make lint
```

### 4. Submit Pull Request
```bash
# Push your branch
git push origin feature/your-feature-name

# Create pull request via GitHub web interface
# Fill out the PR template completely
```

## 🛡️ Branch Protection & Code Review

This repository uses **branch protection rules** to ensure code quality:

### Main Branch Protection
- ✅ **Pull Request Required**: Direct pushes to `main` are not allowed
- ✅ **Code Review Required**: At least 1 approving review needed
- ✅ **CI Checks Required**: All tests must pass before merge
- ✅ **Up-to-date Required**: Branch must be current with main
- ✅ **Code Owners**: Automatic review requests for relevant files

### Required Status Checks
Your pull request must pass these automated checks:
1. **Syntax Validation & Linting** - Lua syntax and style checks
2. **Basic Execution Testing** - Module compilation and unit tests
3. **Mocked Environment Testing** - Docker-based testing
4. **Scribunto Integration Testing** - Full MediaWiki integration

### Pull Request Process
1. **Create PR**: Use descriptive title and fill out template
2. **Automated Testing**: CI pipeline runs automatically
3. **Code Review**: Repository maintainers review changes
4. **Address Feedback**: Make requested changes if any
5. **Approval & Merge**: Maintainer merges after approval

## 📁 Repository Structure & Guidelines

### Source Code Guidelines
- **`src/modules/`** - All Lua module source code (authoritative)
- **`build/modules/`** - Build artifacts (DO NOT EDIT - symlinks only)
- **Follow functional programming patterns** - Pure functions, immutability
- **MediaWiki Compatibility** - Ensure Lua 5.1 and Scribunto compatibility

### Testing Guidelines
- **`tests/`** - Comprehensive test suite
- **Add tests** for new features and bug fixes
- **Run full test pipeline** before submitting PR
- **4-stage testing** - Syntax → Execution → Environment → Integration

### Documentation Guidelines
- **GitHub Wiki** - All user-facing documentation
- **Code Comments** - JSDoc-style type annotations
- **Inline Documentation** - Explain complex algorithms
- **README.md** - Keep updated with major changes

### Scripts and Tools
- **`scripts/`** - Unified development tools only
- **Use existing tools** rather than creating new ones
- **VS Code Integration** - Leverage existing tasks when possible

## 🔒 Security Guidelines

### Environment Variables
- **Never commit secrets** to version control
- **Use `.env.template`** for configuration examples
- **Update `.env.template`** when adding new environment variables
- **Sensitive data** goes in `.env` (gitignored)

### Code Security
- **Input validation** for all public functions
- **Error handling** using CodeStandards.lua patterns
- **No hardcoded credentials** in any files
- **Follow least privilege principle**

## 🧪 Testing Requirements

### Before Submitting PR
```bash
# Run complete test suite
make test

# Fix any linting issues
make fix

# Verify CI pipeline locally
make ci-test
```

### Test Categories
1. **Unit Tests** - Individual function testing
2. **Integration Tests** - Module interaction testing
3. **Environment Tests** - Docker-based MediaWiki testing
4. **Performance Tests** - Benchmark critical paths

## 📋 Code Style & Standards

### Lua Code Style
- **Functional Programming** - Prefer pure functions
- **Consistent Naming** - camelCase for functions, snake_case for variables
- **Type Annotations** - JSDoc-style comments for function signatures
- **Error Handling** - Use CodeStandards.lua patterns
- **Performance** - Consider MediaWiki's execution limits

### Example Function Format
```lua
--- Transforms array elements using functional patterns
-- @param {table} array The input array to transform
-- @param {function} transform The transformation function
-- @return {table} New transformed array
-- @usage local result = Array.map({1,2,3}, function(x) return x * 2 end)
local function map(array, transform)
    -- Implementation here
end
```

### Markdown Style
- **Consistent Headers** - Use ## for main sections
- **Code Blocks** - Specify language for syntax highlighting
- **Links** - Use descriptive link text
- **Lists** - Use - for unordered, 1. for ordered

## 🎯 Contribution Areas

### High Priority
- **Bug Fixes** - Address issues in GitHub Issues
- **Performance Improvements** - Optimize critical functions
- **MediaWiki Integration** - Enhance Scribunto compatibility
- **Test Coverage** - Expand test suite coverage

### Medium Priority
- **Documentation** - Improve wiki pages and code comments
- **Examples** - Add usage examples and demos
- **Tool Improvements** - Enhance development scripts
- **VS Code Integration** - Improve development experience

### Advanced Contributions
- **New Modules** - Additional functional programming utilities
- **Performance Dashboard** - Monitoring and visualization
- **CI/CD Enhancements** - Improve automation pipeline
- **Community Features** - Templates, guides, tutorials

## 🔍 Code Review Guidelines

### For Contributors
- **Self-Review** - Review your own PR before requesting review
- **Clear Description** - Explain what changes and why
- **Link Issues** - Reference related GitHub issues
- **Test Evidence** - Include test results and screenshots
- **Small PRs** - Keep changes focused and manageable

### For Reviewers
- **Constructive Feedback** - Suggest improvements, don't just criticize
- **Functional Correctness** - Verify logic and algorithms
- **Performance Impact** - Consider MediaWiki execution limits
- **Security Review** - Check for potential vulnerabilities
- **Documentation** - Ensure changes are properly documented

## 📞 Getting Help

### Resources
- **[GitHub Wiki](https://github.com/roscroft/mediawiki-lua-library/wiki)** - Comprehensive documentation
- **[GitHub Issues](https://github.com/roscroft/mediawiki-lua-library/issues)** - Bug reports and feature requests
- **[GitHub Discussions](https://github.com/roscroft/mediawiki-lua-library/discussions)** - Community Q&A
- **[Development Guide](https://github.com/roscroft/mediawiki-lua-library/wiki/Development-Guide)** - Technical deep dive

### Support Channels
- **GitHub Issues** - Bug reports, feature requests
- **GitHub Discussions** - General questions and ideas
- **Pull Request Comments** - Code-specific discussions
- **Wiki Comments** - Documentation feedback

## 🎉 Recognition

Contributors are recognized in:
- **GitHub Contributors Graph** - Automatic recognition
- **Release Notes** - Major contributions highlighted
- **Wiki Acknowledgments** - Documentation contributors
- **Code Comments** - Author attribution for significant features

## 📜 License Agreement

By contributing to this project, you agree that your contributions will be licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

## For AI Assistants & Automated Contributors

### Special Guidelines
- **Documentation updates**: Always append to relevant wiki pages
- **Code changes**: Follow functional programming patterns in `src/modules/`
- **Security**: Never commit secrets, use environment variables
- **Testing**: Update tests in `tests/` directory when needed
- **File Structure**: Respect the clean repository structure

### Automated Tools
- **GitHub Actions** - CI/CD pipeline handles automation
- **Dependabot** - Automated dependency updates
- **Code Quality** - Automated linting and formatting
- **Security Scanning** - Automated vulnerability detection

Thank you for contributing to the MediaWiki Lua Module Library! 🚀
