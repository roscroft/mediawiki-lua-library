# GitHub Actions Guide

Comprehensive CI/CD pipeline for automated testing, releases, and maintenance.

## Workflows Overview

### Continuous Integration (`ci.yml`)
Runs on every push/PR with 4-stage testing:

1. **Syntax Validation**: Lua syntax checking and linting
2. **Basic Execution**: Module compilation and unit tests
3. **Mocked Environment**: Docker-based MediaWiki environment testing  
4. **Scribunto Integration**: Full MediaWiki + Scribunto integration testing

### Pull Request Validation
Smart testing based on changed files:
- Lua changes: Full test pipeline
- Documentation changes: Markdown linting only
- Configuration changes: Workflow validation

### Automated Releases (`deployment.yml`)
- Creates releases with artifacts when tags are pushed
- Generates changelog from commit messages
- Uploads build artifacts and documentation

### Scheduled Maintenance
- **Daily health checks**: Repository health monitoring
- **Dependency updates**: Automated Dependabot PRs
- **Security scanning**: Regular security audits

## Usage

### Running Locally

```bash
# Run CI pipeline locally (fast)
make ci-test

# Run full CI pipeline with Docker
make ci-local  

# Validate GitHub Actions workflows
make validate-workflows
```

### Creating Releases

```bash
# Tag a new version
git tag v1.2.3
git push origin v1.2.3

# GitHub Actions will automatically:
# 1. Run full test suite
# 2. Create release with artifacts
# 3. Generate changelog
# 4. Deploy documentation
```

### Monitoring

- **Actions tab**: View workflow runs and logs
- **Security tab**: View security alerts and updates
- **Insights tab**: View repository metrics and health

## Configuration

### Workflow Files

```text
.github/workflows/
├── ci.yml                 # Main CI/CD pipeline
├── deployment.yml         # Release automation
├── documentation.yml      # Documentation updates
├── project-management.yml # Project automation
└── security-quality.yml  # Security and quality checks
```

### Environment Variables

Required secrets in repository settings:
- `GITHUB_TOKEN`: Automatically provided
- `DOCKER_USERNAME`: For Docker Hub (if needed)
- `DOCKER_PASSWORD`: For Docker Hub (if needed)

For more details on development workflow, see [Development Guide](Development-Guide).
