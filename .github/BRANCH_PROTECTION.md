# Branch Protection Rules for MediaWiki Lua Library

This document describes the branch protection rules that should be configured on GitHub to protect the `main` branch and ensure code quality.

## Required Branch Protection Rules

### Main Branch Protection

Configure the following rules for the `main` branch in GitHub:

#### 1. **Restrict pushes that create files**
- ✅ Require pull request reviews before merging
- ✅ Require review from code owners (when CODEOWNERS file exists)
- ✅ Dismiss stale reviews when new commits are pushed
- ✅ Require review from at least **2** reviewers for significant changes

#### 2. **Require status checks to pass**
- ✅ Require branches to be up to date before merging
- ✅ Required status checks:
  - `Syntax Validation & Linting`
  - `Basic Execution Testing`
  - `Mocked Environment Testing`
  - `Scribunto Integration Testing`
  - `Security Quality Check`

#### 3. **Enforce restrictions**
- ✅ Restrict pushes to only administrators and repository maintainers
- ✅ Allow force pushes by administrators only (for emergency fixes)
- ✅ Allow deletions by administrators only

#### 4. **Additional protections**
- ✅ Require signed commits
- ✅ Require linear history
- ✅ Include administrators in restrictions

## GitHub Repository Rulesets (Recommended)

For modern GitHub repositories, use Repository Rulesets instead of legacy branch protection:

### Ruleset Configuration

```yaml
# This would be configured in GitHub UI or via API
name: "Main Branch Protection"
target: "branch"
enforcement: "active"

conditions:
  ref_name:
    include:
      - "refs/heads/main"

rules:
  - type: "pull_request"
    parameters:
      dismiss_stale_reviews_on_push: true
      require_code_owner_review: true
      require_last_push_approval: true
      required_approving_review_count: 1
      required_review_thread_resolution: true

  - type: "required_status_checks"
    parameters:
      required_status_checks:
        - context: "Syntax Validation & Linting"
          integration_id: 15368  # GitHub Actions
        - context: "Basic Execution Testing"
          integration_id: 15368
        - context: "Mocked Environment Testing"
          integration_id: 15368
        - context: "Scribunto Integration Testing"
          integration_id: 15368
        - context: "Security Quality Check"
          integration_id: 15368
      strict_required_status_checks_policy: true

  - type: "non_fast_forward"
    parameters: {}

  - type: "restrict_pushes"
    parameters:
      restrict_pushes_to_admins: false

  - type: "restrict_deletions"
    parameters: {}

bypass_actors:
  - actor_id: 1  # Repository owner
    actor_type: "OrganizationAdmin"
    bypass_mode: "always"
```

## Manual Setup Instructions

### Via GitHub Web Interface

1. **Navigate to Repository Settings**
   - Go to `https://github.com/roscroft/mediawiki-lua-library/settings`
   - Click on "Branches" in the left sidebar

2. **Add Branch Protection Rule**
   - Click "Add rule"
   - Enter branch name pattern: `main`

3. **Configure Protection Settings**
   - ✅ Require pull request reviews before merging
     - Required number of reviewers: 1
     - ✅ Dismiss stale reviews when new commits are pushed
     - ✅ Require review from code owners
   
   - ✅ Require status checks to pass before merging
     - ✅ Require branches to be up to date before merging
     - Select required checks:
       - `Syntax Validation & Linting`
       - `Basic Execution Testing`
       - `Mocked Environment Testing`
       - `Scribunto Integration Testing`
   
   - ✅ Require conversation resolution before merging
   - ✅ Require signed commits
   - ✅ Require linear history
   - ✅ Include administrators

### Via GitHub CLI

```bash
# Install GitHub CLI if not already installed
# Set up the main branch protection
gh api repos/roscroft/mediawiki-lua-library/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["Syntax Validation & Linting","Basic Execution Testing","Mocked Environment Testing","Scribunto Integration Testing"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":true,"required_approving_review_count":1}' \
  --field restrictions='{"users":[],"teams":[],"apps":[]}' \
  --field allow_force_pushes=false \
  --field allow_deletions=false
```

## CODEOWNERS File

Consider creating a `.github/CODEOWNERS` file to automatically request reviews from specific users:

```
# MediaWiki Lua Library Code Owners

# Default owners for everything in the repo
* @roscroft

# Source code requires additional review
/src/ @roscroft
/tests/ @roscroft

# GitHub Actions and CI/CD
/.github/ @roscroft

# Documentation
/README.md @roscroft
/CONTRIBUTING.md @roscroft

# Scripts and automation
/scripts/ @roscroft
```

## Contribution Workflow

With these protections in place, the standard workflow becomes:

1. **Create Feature Branch**: `git checkout -b feature/new-feature`
2. **Make Changes**: Develop and test locally
3. **Push Branch**: `git push origin feature/new-feature`
4. **Create Pull Request**: Via GitHub web interface
5. **Automated Testing**: All CI checks must pass
6. **Code Review**: At least 1 approving review required
7. **Merge**: Only possible after all requirements met

## Benefits

- 🛡️ **Code Quality**: All changes go through CI pipeline
- 👥 **Collaboration**: Mandatory code reviews improve knowledge sharing
- 🔒 **Security**: Signed commits and restricted access
- 📈 **Reliability**: Prevents breaking changes from reaching main
- 🚀 **Automation**: Automated enforcement reduces manual oversight

## Emergency Procedures

In case of critical hotfixes, administrators can:

1. **Temporarily disable protection** (if absolutely necessary)
2. **Use emergency bypass** (if configured)
3. **Create and fast-track hotfix PR** with expedited review

**Note**: All emergency changes should be followed up with proper documentation and post-incident review.
