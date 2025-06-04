.PHONY: fix lint test setup

fix:
	@echo "Running auto-fixes..."
	@./scripts/auto-fix.sh

lint:
	@echo "Running linters..."
	@luacheck src/modules/*.lua || true
	@npx markdownlint docs/*.md *.md --config .markdownlint.json || true

test:
	@echo "Running tests..."
	@bash tests/scripts/test-pipeline.sh

setup:
	@echo "Setting up development environment..."
	@npm install
	@chmod +x scripts/*.sh
	@chmod +x .git/hooks/pre-commit

all: setup fix lint test