#!/bin/bash
#
# Deploy Wiki Content to GitHub
# Deploys generated wiki content to GitHub Wiki repository
#

set -e

WIKI_CONTENT_DIR="docs"
WIKI_REPO="https://github.com/roscroft/mediawiki-lua-library.wiki.git"
TEMP_DIR="temp-wiki-deploy"

echo "🚀 Deploying Wiki Content to GitHub..."

# Check if wiki content exists
if [ ! -d "$WIKI_CONTENT_DIR" ]; then
    echo "❌ Error: Wiki content directory not found: $WIKI_CONTENT_DIR"
    echo "Run ./scripts/generate-wiki-quick.sh first"
    exit 1
fi

# Count wiki pages
WIKI_COUNT=$(find "$WIKI_CONTENT_DIR" -name "*.md" | wc -l)
if [ "$WIKI_COUNT" -eq 0 ]; then
    echo "❌ Error: No wiki pages found in $WIKI_CONTENT_DIR"
    echo "Run ./scripts/generate-wiki-quick.sh first"
    exit 1
fi

echo "📄 Found $WIKI_COUNT wiki pages to deploy"

# Clean up any existing temp directory
rm -rf "$TEMP_DIR"

# Clone wiki repository
echo "📥 Cloning GitHub Wiki repository..."
if ! git clone "$WIKI_REPO" "$TEMP_DIR"; then
    echo "❌ Error: Failed to clone wiki repository"
    echo "Check your internet connection and repository access"
    exit 1
fi

# Copy wiki content
echo "📋 Copying wiki content..."
cp "$WIKI_CONTENT_DIR"/*.md "$TEMP_DIR"/

# Deploy to GitHub
cd "$TEMP_DIR"

# Detect and switch to the correct default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
CURRENT_BRANCH=$(git branch --show-current)
echo "📋 Wiki repository default branch: $DEFAULT_BRANCH"
echo "📋 Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
    echo "🔄 Switching to default branch: $DEFAULT_BRANCH"
    git checkout "$DEFAULT_BRANCH"
fi

echo "📝 Staging changes..."
git add .

if git diff --staged --quiet; then
    echo "ℹ️  No changes to deploy - wiki is already up to date"
else
    echo "💾 Committing changes..."
    git commit -m "Deploy MediaWiki Lua Library documentation

- Complete Home page with navigation and module overview
- Getting Started guide with installation and setup  
- Development Guide with architecture and patterns
- Testing documentation with framework and procedures
- Security guidelines and configuration
- GitHub Actions CI/CD documentation
- Project Status with roadmap and current state

Auto-generated from repository documentation."

    echo "🚀 Pushing to GitHub Wiki..."
    
    # Detect the default branch (master or main)
    DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
    echo "📋 Detected default branch: $DEFAULT_BRANCH"
    
    # If we're on a different branch, switch to the default branch
    CURRENT_BRANCH=$(git branch --show-current)
    if [ "$CURRENT_BRANCH" != "$DEFAULT_BRANCH" ]; then
        echo "🔄 Switching from $CURRENT_BRANCH to $DEFAULT_BRANCH"
        git checkout "$DEFAULT_BRANCH"
    fi
    
    if git push origin "$DEFAULT_BRANCH"; then
        echo "✅ Wiki deployment successful!"
        echo "🌐 View at: https://github.com/roscroft/mediawiki-lua-library/wiki"
    else
        echo "❌ Error: Failed to push to GitHub"
        echo "Check your network connection and try again"
        exit 1
    fi
fi

# Cleanup
cd ..
rm -rf "$TEMP_DIR"

echo "🎉 Wiki deployment complete!"
echo "📚 Wiki Pages: $WIKI_COUNT"
echo "🔗 GitHub Wiki: https://github.com/roscroft/mediawiki-lua-library/wiki"
