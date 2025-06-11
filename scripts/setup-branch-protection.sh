#!/bin/bash
#
# Branch Protection Setup Helper
# Provides instructions and commands for setting up GitHub branch protection
#

set -e

REPO_OWNER="roscroft"
REPO_NAME="mediawiki-lua-library"
REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME"

echo "🛡️ MediaWiki Lua Library - Branch Protection Setup"
echo "=================================================="
echo ""
echo "This script helps you set up branch protection rules for the main branch."
echo ""

# Check if GitHub CLI is available
if command -v gh >/dev/null 2>&1; then
    echo "✅ GitHub CLI detected"
    GH_AVAILABLE=true
else
    echo "⚠️  GitHub CLI not found - manual setup required"
    GH_AVAILABLE=false
fi

echo ""

# Check current repository status
echo "📋 Repository Information:"
echo "   Repository: $REPO_URL"
echo "   Main branch: main"
echo "   Current directory: $(pwd)"
echo ""

# Function to display manual setup instructions
show_manual_instructions() {
    echo "📖 Manual Setup Instructions:"
    echo ""
    echo "1. **Go to Repository Settings**"
    echo "   → $REPO_URL/settings/branches"
    echo ""
    echo "2. **Add Branch Protection Rule**"
    echo "   → Click 'Add rule'"
    echo "   → Branch name pattern: main"
    echo ""
    echo "3. **Required Settings**:"
    echo "   ✅ Require pull request reviews before merging"
    echo "      → Required number of reviewers: 1"
    echo "      ✅ Dismiss stale reviews when new commits are pushed"
    echo "      ✅ Require review from code owners"
    echo ""
    echo "   ✅ Require status checks to pass before merging"
    echo "      ✅ Require branches to be up to date before merging"
    echo "      → Required status checks:"
    echo "        • Syntax Validation & Linting"
    echo "        • Basic Execution Testing"
    echo "        • Mocked Environment Testing"
    echo "        • Scribunto Integration Testing"
    echo ""
    echo "   ✅ Require conversation resolution before merging"
    echo "   ✅ Require signed commits"
    echo "   ✅ Require linear history"
    echo "   ✅ Include administrators"
    echo ""
    echo "4. **Save Protection Rule**"
    echo "   → Click 'Create' to apply the rules"
    echo ""
}

# Function to attempt automated setup
attempt_automated_setup() {
    echo "🤖 Attempting Automated Setup..."
    echo ""
    
    # Check authentication
    if ! gh auth status >/dev/null 2>&1; then
        echo "❌ GitHub CLI not authenticated"
        echo "   Run: gh auth login"
        echo ""
        return 1
    fi
    
    echo "✅ GitHub CLI authenticated"
    
    # Check repository access
    if ! gh repo view "$REPO_OWNER/$REPO_NAME" >/dev/null 2>&1; then
        echo "❌ Cannot access repository: $REPO_OWNER/$REPO_NAME"
        echo "   Check repository name and permissions"
        echo ""
        return 1
    fi
    
    echo "✅ Repository access confirmed"
    
    # Apply branch protection rules
    echo ""
    echo "🔧 Applying branch protection rules..."
    
    # Note: This command requires admin permissions
    if gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/main/protection \
        --method PUT \
        --field required_status_checks='{
            "strict": true,
            "contexts": [
                "Syntax Validation & Linting",
                "Basic Execution Testing", 
                "Mocked Environment Testing",
                "Scribunto Integration Testing"
            ]
        }' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{
            "dismiss_stale_reviews": true,
            "require_code_owner_reviews": true,
            "required_approving_review_count": 1,
            "require_last_push_approval": false
        }' \
        --field restrictions='{"users":[],"teams":[],"apps":[]}' \
        --field allow_force_pushes=false \
        --field allow_deletions=false >/dev/null 2>&1; then
        
        echo "✅ Branch protection rules applied successfully!"
        echo ""
        
        # Verify the setup
        echo "🔍 Verifying protection rules..."
        if gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/main/protection >/dev/null 2>&1; then
            echo "✅ Protection rules verified and active"
            echo ""
            echo "🎉 Automated setup complete!"
            return 0
        else
            echo "⚠️  Rules applied but verification failed"
            return 1
        fi
    else
        echo "❌ Failed to apply protection rules"
        echo "   This may require admin permissions or manual setup"
        echo ""
        return 1
    fi
}

# Function to verify current protection status
check_current_protection() {
    echo "🔍 Checking Current Protection Status..."
    echo ""
    
    if ! $GH_AVAILABLE; then
        echo "⚠️  GitHub CLI not available - cannot check status"
        echo "   Manual verification required at: $REPO_URL/settings/branches"
        echo ""
        return
    fi
    
    if gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/main/protection >/dev/null 2>&1; then
        echo "✅ Branch protection is currently active on main branch"
        echo ""
        echo "📋 Current status checks required:"
        gh api repos/"$REPO_OWNER"/"$REPO_NAME"/branches/main/protection \
            --jq '.required_status_checks.contexts[]' 2>/dev/null | sed 's/^/   • /' || echo "   (Unable to retrieve status checks)"
        echo ""
    else
        echo "❌ No branch protection detected on main branch"
        echo "   Setup required!"
        echo ""
    fi
}

# Function to show post-setup verification
show_verification_steps() {
    echo "✅ Post-Setup Verification:"
    echo ""
    echo "1. **Verify Protection Rules**"
    echo "   → $REPO_URL/settings/branches"
    echo "   → Confirm all settings are active"
    echo ""
    echo "2. **Test the Workflow**"
    echo "   → Create a test branch: git checkout -b test/branch-protection"
    echo "   → Make a small change: echo '# Test' >> README.md"
    echo "   → Push and create PR: git push origin test/branch-protection"
    echo "   → Verify you cannot merge without review"
    echo ""
    echo "3. **Verify CI Integration**"
    echo "   → Confirm all CI checks run on PRs"
    echo "   → Verify merge is blocked until checks pass"
    echo ""
    echo "4. **Test Code Owners**"
    echo "   → Verify automatic review requests work"
    echo "   → Check .github/CODEOWNERS is functioning"
    echo ""
}

# Main execution
echo "🔍 Step 1: Checking Current Status"
check_current_protection

echo "🚀 Step 2: Setup Options"
echo ""
echo "Choose your setup method:"
echo "1. Automated setup (requires GitHub CLI and admin permissions)"
echo "2. Manual setup (detailed instructions provided)"
echo "3. Skip setup (just show verification steps)"
echo ""

# If this is being run interactively, prompt for choice
if [ -t 0 ]; then
    read -p "Enter your choice (1-3): " choice
    echo ""
else
    # Non-interactive mode - try automated first, fall back to manual
    choice="1"
    echo "Running in non-interactive mode - attempting automated setup..."
    echo ""
fi

case $choice in
    1)
        if $GH_AVAILABLE; then
            if attempt_automated_setup; then
                show_verification_steps
                exit 0
            else
                echo "🔄 Automated setup failed - showing manual instructions:"
                echo ""
                show_manual_instructions
            fi
        else
            echo "❌ GitHub CLI not available for automated setup"
            echo ""
            show_manual_instructions
        fi
        ;;
    2)
        show_manual_instructions
        ;;
    3)
        echo "⏭️  Skipping setup..."
        echo ""
        ;;
    *)
        echo "❌ Invalid choice - showing manual instructions:"
        echo ""
        show_manual_instructions
        ;;
esac

show_verification_steps

echo "📚 Additional Resources:"
echo "   • Branch Protection Documentation: .github/BRANCH_PROTECTION.md"
echo "   • Contributing Guidelines: CONTRIBUTING.md"
echo "   • Code Owners: .github/CODEOWNERS"
echo "   • Pull Request Template: .github/pull_request_template.md"
echo ""
echo "🎯 Benefits of Branch Protection:"
echo "   🛡️ Prevents direct pushes to main branch"
echo "   👥 Enforces code review process"
echo "   🧪 Ensures all tests pass before merge"
echo "   🔒 Maintains code quality and security"
echo "   📋 Standardizes contribution workflow"
echo ""
echo "✨ Setup complete! Your repository is now protected."
