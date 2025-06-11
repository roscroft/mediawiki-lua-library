# 🧹 PROJECT CLEANUP PLAN

## PHASE 1: REMOVE ONE-TIME-USE FILES

### Wiki Migration Scripts (Complete - Can Remove)

- ✅ scripts/migrate-to-wiki.sh
- ✅ scripts/complete-wiki-migration.sh  
- ✅ scripts/deploy-wiki.sh
- ✅ scripts/force-wiki-deploy.sh
- ✅ scripts/prepare-wiki-content.sh
- ✅ scripts/simple-wiki-deploy.sh
- ✅ scripts/generate-wiki-docs.lua
- ✅ scripts/test-ssh-setup.sh

### Archive Directories (Can Remove Entirely)

- ✅ scripts/archive-20250611/ (14 archived scripts)
- ✅ scripts/wiki-content/ (wiki content now deployed)
- ✅ scripts/wiki-ready/ (deployment staging area)

### Setup/Migration Scripts (One-Time Use)

- ✅ scripts/consolidate-scripts.sh
- ✅ scripts/setup-build-links.sh (build links already created)

## PHASE 2: REMOVE REDUNDANT DOCUMENTATION

### Root Directory Cleanup

- ✅ SSH-SETUP-GUIDE.md (temporary setup guide)
- ✅ WIKI-ENABLEMENT-GUIDE.md (one-time instructions)  
- ✅ WIKI-FINAL-SOLUTION.md (one-time instructions)
- ✅ CONVERSION_EXAMPLE.md (can move to examples/ if needed)
- ✅ DEPENDENCY_SIMPLIFICATION_SOLUTION.md (temporary analysis)

### Documentation Now in Wiki

- ✅ docs/README.md (migration notice - no longer needed)
- ✅ docs/usage.md → Now in wiki as Getting-Started
- ✅ docs/testing.md → Now in wiki as Testing
- ✅ docs/development-history.md → Now in wiki as Development-Guide
- ✅ docs/github-actions-guide.md → Now in wiki as GitHub-Actions
- ✅ docs/PROJECT_STATUS.md → Now in wiki as Project-Status
- ✅ docs/SECURITY.md → Now in wiki as Security
- ✅ docs/code-refactoring-analysis.md → Now in wiki
- ✅ docs/PERFORMANCE_DASHBOARD_STATUS.md → Now in wiki

### Status/Report Files (Completed Work)

- ✅ docs/HELPER_MODULE_CLEANUP_REPORT.md
- ✅ docs/HELPER_MODULE_ENHANCEMENT_FINAL_REPORT.md  
- ✅ docs/GITHUB_ACTIONS_MIGRATION_COMPLETE.md
- ✅ docs/SECURITY_REMEDIATION_COMPLETE.md

## PHASE 3: REMOVE DUPLICATE/OBSOLETE SCRIPTS

### Old/Redundant Script Versions

- ✅ scripts/demo-refactored-system.sh (replaced by demo-unified.lua)
- ✅ scripts/generate-docs-refactored.lua (replaced by unified version)
- ✅ scripts/final-demonstration.lua (obsolete demo)
- ✅ scripts/migration-example.lua (one-time example)
- ✅ scripts/test-functional-core.lua (incorporated into unified)

## PHASE 4: KEEP ESSENTIAL FILES

### Core Scripts (Keep)

- ✅ scripts/demo-unified.lua
- ✅ scripts/generate-docs-unified.lua  
- ✅ scripts/test-unified.lua
- ✅ scripts/auto-fix.sh
- ✅ scripts/cleanup.sh
- ✅ scripts/generate-module-docs.sh
- ✅ scripts/start-mediawiki.sh
- ✅ scripts/view-dashboard.sh
- ✅ scripts/rebuild-docker-image.sh

### Essential Documentation (Keep)

- ✅ README.md (updated to link to wiki)
- ✅ CONTRIBUTING.md
- ✅ LICENSE

## PHASE 5: UPDATE .GITIGNORE

### Add Temporary/Local Files

- Wiki migration artifacts
- SSH setup files  
- Local configuration backups
- One-time scripts

---

## EXECUTION SUMMARY

- **Remove**: ~35 files/directories
- **Keep**: ~12 essential scripts + core docs
- **Cleanup**: docs/ folder → keep minimal API docs only
- **Result**: Clean, maintainable repository focused on core functionality

## SIZE REDUCTION ESTIMATE

- Before: ~200+ files in scripts/docs
- After: ~15-20 essential files
- Space saved: ~80% reduction in non-core files
