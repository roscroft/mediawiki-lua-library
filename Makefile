.PHONY: fix lint test setup ci-test ci-local validate-workflows

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

# GitHub Actions related targets
ci-test:
	@echo "Running CI pipeline locally..."
	@echo "Stage 1: Syntax validation"
	@luacheck src/modules/*.lua || true
	@echo "Stage 2: Unit tests"
	@cd tests && lua run_all_tests.lua
	@echo "Stage 3: Integration tests"  
	@for test in tests/integration/*.lua; do \
		if [ -f "$$test" ]; then \
			echo "Running: $$(basename "$$test")"; \
			lua "$$test"; \
		fi \
	done

ci-local:
	@echo "Running full CI pipeline locally with Docker..."
	@bash tests/scripts/test-pipeline.sh

validate-workflows:
	@echo "Validating GitHub Actions workflows..."
	@if command -v yamllint >/dev/null 2>&1; then \
		yamllint .github/workflows/*.yml; \
	else \
		echo "yamllint not installed - install with: pip install yamllint"; \
	fi
	@echo "Checking workflow syntax..."
	@for workflow in .github/workflows/*.yml; do \
		echo "Checking $$workflow"; \
		python -c "import yaml; yaml.safe_load(open('$$workflow'))" || echo "Invalid YAML in $$workflow"; \
	done

gh-actions-help:
	@echo "GitHub Actions Commands:"
	@echo "  make ci-test          - Run CI pipeline locally (fast)"
	@echo "  make ci-local         - Run full CI pipeline with Docker"
	@echo "  make validate-workflows - Validate workflow files"
	@echo ""
	@echo "Workflow triggers:"
	@echo "  • Push to main/develop → Full CI pipeline"
	@echo "  • Pull Request → PR validation pipeline"  
	@echo "  • Daily at 6 AM UTC → Maintenance checks"
	@echo "  • Manual → Release workflow"

all: setup fix lint test