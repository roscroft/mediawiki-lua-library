# GitHub Actions CI/CD Pipeline Guide

This document describes the comprehensive GitHub Actions setup for the MediaWiki Lua Module Library project.

## Overview

The project uses a multi-workflow approach to ensure code quality, automate testing, and streamline releases:

1. **Continuous Integration (CI)** - Main testing pipeline
2. **Pull Request Validation** - PR-specific checks
3. **Release Management** - Automated releases
4. **Scheduled Maintenance** - Daily health checks
5. **Dependency Management** - Automated updates

## Workflows

### 1. Continuous Integration (`ci.yml`)

**Triggers**: Push to `main`/`develop`, Pull Requests

**4-Stage Pipeline**:
- **Stage 1**: Syntax Validation & Linting
- **Stage 2**: Basic Lua Execution Tests  
- **Stage 3**: Mocked Environment Testing
- **Stage 4**: Scribunto Integration Testing

**Matrix Testing**: Lua 5.1 and 5.3 support

**Features**:
- Docker layer caching for faster builds
- Parallel job execution
- Performance testing
- Security scanning
- Comprehensive test reporting

### 2. Pull Request Validation (`pr-validation.yml`)

**Triggers**: PR opened, synchronized, reopened

**Intelligent Testing**:
- Detects changed files (Lua, docs, tests, config)
- Runs appropriate tests based on changes
- Quick feedback loop for fast iteration
- Matrix testing for comprehensive validation

**Checks**:
- PR title and description validation
- Code quality analysis with luacheck
- Documentation completeness
- Security scanning for secrets
- Performance regression detection

### 3. Release Management (`release.yml`)

**Triggers**: Git tags (`v*`), Manual workflow dispatch

**Release Process**:
- Pre-release validation (full test suite)
- Build release artifacts (archives, modules-only)
- Docker image creation and testing
- Performance benchmarking
- GitHub release creation with assets

**Artifacts**:
- `mediawiki-lua-library-vX.Y.Z.tar.gz` - Complete library
- `mediawiki-lua-modules-vX.Y.Z.tar.gz` - Modules only
- Docker images with version tags
- Performance reports

### 4. Scheduled Maintenance (`maintenance.yml`)

**Triggers**: Daily at 6:00 AM UTC, Manual

**Daily Checks**:
- Health monitoring (syntax, module loading)
- Dependency update detection
- Performance regression monitoring
- Security auditing
- Code quality metrics
- Cleanup of old artifacts

### 5. Dependency Management (`dependabot.yml`)

**Automated Updates**:
- GitHub Actions (weekly, Mondays)
- NPM packages (weekly, Tuesdays)  
- Docker images (monthly, first Monday)

**Features**:
- Grouped minor/patch updates
- Automatic PR creation
- Reviewer assignment
- Conventional commit messages

## Setup Instructions

### 1. Repository Setup

```bash
# Ensure .github directory structure exists
mkdir -p .github/{workflows,ISSUE_TEMPLATE}

# Workflows are automatically active once committed to main
git add .github/
git commit -m "feat: add GitHub Actions CI/CD pipeline"
git push origin main
```

### 2. Required Secrets (Optional)

For advanced features, configure these repository secrets in GitHub:

```bash
# For Docker Hub publishing (optional)
DOCKER_USERNAME=your-docker-username
DOCKER_PASSWORD=your-docker-password

# For enhanced notifications (optional)
SLACK_WEBHOOK_URL=your-slack-webhook
```

### 3. Branch Protection

Configure branch protection rules for `main`:

```yaml
# Settings → Branches → Add rule
Branch name pattern: main
Settings:
  ✅ Require status checks to pass before merging
  ✅ Require branches to be up to date before merging
  Required status checks:
    - Syntax Validation & Linting
    - Basic Lua Execution  
    - Mocked Environment Testing
    - PR Validation Summary
  ✅ Require pull request reviews before merging
  ✅ Dismiss stale PR approvals when new commits are pushed
  ✅ Restrict pushes that create files larger than 100 MB
```

## Local Development

### Running CI Locally

```bash
# Quick local CI check
make ci-test

# Full CI pipeline with Docker
make ci-local

# Validate workflow files
make validate-workflows

# Get help with GitHub Actions commands
make gh-actions-help
```

### Testing Workflow Changes

```bash
# Test workflow syntax
python -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"

# Validate with act (GitHub Actions local runner)
act -n  # Dry run
act     # Full run (requires Docker)
```

## Workflow Customization

### Adding New Test Stages

1. **Add to CI workflow**:
```yaml
- name: New Test Stage
  run: |
    echo "Running new tests..."
    # Your test commands
```

2. **Update Makefile**:
```makefile
new-test:
	@echo "Running new test..."
	# Your test commands
```

3. **Add to PR validation** (if needed):
```yaml
- name: Run new tests on PR
  if: needs.pr-validation.outputs.has-relevant-changes == 'true'
  run: make new-test
```

### Environment-Specific Configuration

```yaml
# Add environment variables
env:
  CUSTOM_VAR: value
  
# Matrix for different environments
strategy:
  matrix:
    environment: [development, staging, production]
    lua-version: [5.1, 5.3]
```

### Custom Notifications

```yaml
- name: Notify on failure
  if: failure()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
      -H 'Content-type: application/json' \
      --data '{"text":"Build failed for ${{ github.repository }}"}'
```

## Monitoring and Observability

### GitHub Actions Dashboard

Monitor workflow runs at: `https://github.com/YOUR-ORG/wiki-lua/actions`

### Key Metrics to Monitor

- **Success Rate**: Percentage of successful CI runs
- **Duration**: Time taken for different stages
- **Flaky Tests**: Tests that fail intermittently
- **Performance**: Trends in performance test results

### Troubleshooting Common Issues

1. **Docker Build Failures**:
   - Check Docker layer caching
   - Verify Dockerfile syntax
   - Ensure sufficient disk space

2. **Test Timeouts**:
   - Increase timeout values
   - Optimize test performance
   - Use parallel execution

3. **Permission Errors**:
   - Check file permissions in repo
   - Verify GitHub token permissions
   - Review branch protection settings

## Best Practices

### Workflow Design

- **Fast Feedback**: Quick checks first, comprehensive tests later
- **Fail Fast**: Stop on critical failures to save resources
- **Parallel Execution**: Run independent tests in parallel
- **Caching**: Cache dependencies and Docker layers
- **Conditional Execution**: Skip unnecessary tests based on changes

### Security

- **Secret Management**: Use GitHub secrets for sensitive data
- **Least Privilege**: Limit workflow permissions
- **Dependency Scanning**: Regularly update dependencies
- **Code Scanning**: Use security analysis tools

### Maintenance

- **Regular Updates**: Keep actions and dependencies current
- **Performance Monitoring**: Track CI/CD performance metrics
- **Cost Management**: Optimize workflows for efficiency
- **Documentation**: Keep workflows well-documented

## Migration from Local Testing

If migrating from local testing scripts:

1. **Map existing stages** to GitHub Actions jobs
2. **Convert shell scripts** to workflow steps
3. **Set up caching** for dependencies
4. **Configure notifications** for failures
5. **Test thoroughly** before enabling on main branch

## Integration with VS Code

The workflows complement existing VS Code tasks:

- **Local Development**: Use VS Code tasks for quick testing
- **Pre-commit Validation**: Use GitHub Actions for comprehensive testing
- **Release Management**: Automated through GitHub workflows

## Support and Troubleshooting

### Getting Help

1. **GitHub Actions Documentation**: https://docs.github.com/actions
2. **Community Forums**: GitHub Community Discussions
3. **Project Issues**: Use issue templates for workflow problems

### Common Commands

```bash
# View workflow runs
gh run list

# View specific run details  
gh run view <run-id>

# Re-run failed workflows
gh run rerun <run-id>

# Cancel running workflow
gh run cancel <run-id>
```

This setup provides a robust, scalable CI/CD pipeline that ensures code quality, automates testing, and streamlines the development process while maintaining the high standards established in your local development environment.
