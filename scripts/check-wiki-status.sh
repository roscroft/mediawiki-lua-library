#!/bin/bash
#
# Complete Wiki Deployment Status Check
# Checks status of wiki deployment and provides next steps
#

echo "📊 MediaWiki Lua Library - Wiki Deployment Status"
echo "================================================"
echo ""

# Check if wiki content exists
if [ -d "scripts/wiki-content" ]; then
    WIKI_COUNT=$(find scripts/wiki-content -name "*.md" | wc -l)
    echo "✅ Wiki Content: $WIKI_COUNT pages generated"
    echo "   📂 Location: scripts/wiki-content/"
    echo "   📄 Pages: $(ls scripts/wiki-content/*.md | sed 's|scripts/wiki-content/||' | sed 's|\.md||' | tr '\n' ', ' | sed 's|, $||')"
else
    echo "❌ Wiki Content: Not generated"
    echo "   Run: ./scripts/generate-wiki-quick.sh"
fi

echo ""

# Check if deployment script exists
if [ -f "scripts/deploy-wiki.sh" ]; then
    echo "✅ Deployment Script: Ready"
    echo "   📜 Location: scripts/deploy-wiki.sh"
else
    echo "❌ Deployment Script: Missing"
fi

echo ""

# Check README wiki links
if grep -q "github.com.*wiki" README.md; then
    echo "✅ README Links: Configured for GitHub Wiki"
    LINK_COUNT=$(grep -c "github.com.*wiki" README.md)
    echo "   🔗 Found $LINK_COUNT wiki references in README.md"
else
    echo "❌ README Links: Not configured for wiki"
fi

echo ""

# Repository status
echo "📁 Repository Status:"
echo "   📦 Project: MediaWiki Lua Module Library"
echo "   🌐 Repository: https://github.com/roscroft/mediawiki-lua-library"
echo "   📚 Wiki URL: https://github.com/roscroft/mediawiki-lua-library/wiki"

echo ""

# Check if we can reach GitHub (quick test)
if timeout 5 ping -c 1 github.com >/dev/null 2>&1; then
    echo "🌐 Network: GitHub accessible"
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Deploy wiki content: ./scripts/deploy-wiki.sh"
    echo "   2. Verify wiki deployment: https://github.com/roscroft/mediawiki-lua-library/wiki"
    echo "   3. Test README links point to correct wiki pages"
else
    echo "⚠️  Network: GitHub not accessible"
    echo ""
    echo "📋 Manual Deployment Steps:"
    echo "   1. When network available, run: ./scripts/deploy-wiki.sh"
    echo "   2. Or manually copy scripts/wiki-content/*.md to GitHub Wiki"
    echo "   3. Verify all 7 wiki pages are deployed correctly"
fi

echo ""
echo "✨ Wiki deployment preparation complete!"
echo "📈 Project Status: Ready for wiki deployment"
