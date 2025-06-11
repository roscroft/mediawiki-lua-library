# Makefile for Lua Documentation Generator

# Default target
.PHONY: all
all: test

# Run tests
.PHONY: test
test:
	@echo "Running test suite..."
	@lua tests/run-tests.lua

# Generate documentation for examples
.PHONY: docs
docs:
	@echo "Generating example documentation..."
	@lua bin/generate-docs.lua --config config/default.lua --input examples --output docs/examples

# Generate documentation using MediaWiki config
.PHONY: docs-mediawiki
docs-mediawiki:
	@echo "Generating MediaWiki documentation..."
	@lua bin/generate-docs.lua --config config/mediawiki.lua

# Clean generated files
.PHONY: clean
clean:
	@echo "Cleaning generated files..."
	@rm -rf docs/examples
	@rm -rf output
	@rm -rf test-output

# Install dependencies (if any)
.PHONY: install
install:
	@echo "No dependencies to install for pure Lua implementation"

# Run example usage
.PHONY: examples
examples:
	@echo "Running example usage..."
	@lua examples/basic-usage.lua

# Validate Lua syntax
.PHONY: syntax
syntax:
	@echo "Validating Lua syntax..."
	@find . -name "*.lua" -exec lua -c {} \;

# Check code style (if luacheck is available)
.PHONY: lint
lint:
	@if command -v luacheck >/dev/null 2>&1; then \
		echo "Running luacheck..."; \
		luacheck lib bin examples tests; \
	else \
		echo "luacheck not available, skipping lint check"; \
	fi

# Package for distribution
.PHONY: package
package: clean test
	@echo "Creating package..."
	@tar -czf lua-docs-generator.tar.gz bin lib templates config examples tests README.md Makefile

# Help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all       - Run tests (default)"
	@echo "  test      - Run test suite"
	@echo "  docs      - Generate example documentation"
	@echo "  clean     - Clean generated files"
	@echo "  examples  - Run example usage"
	@echo "  syntax    - Validate Lua syntax"
	@echo "  lint      - Run code linter (if available)"
	@echo "  package   - Create distribution package"
	@echo "  help      - Show this help"
