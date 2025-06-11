#!/bin/bash
#
# Copilot Instructions Automation Helper
# Automates manual processes mentioned in copilot instructions
#

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 Copilot Instructions Automation Helper${NC}"
echo "=========================================="

# Function to validate file creation safety
validate_file_creation() {
    echo -e "\n${YELLOW}🔍 Running File Creation Safety Validation...${NC}"
    
    # Check for empty files
    empty_files=$(find . -name "*.lua" -o -name "*.sh" -o -name "*.md" | xargs -I {} sh -c 'test ! -s "{}" && echo "{}"' 2>/dev/null || true)
    
    if [ -n "$empty_files" ]; then
        echo -e "${RED}❌ Found empty files:${NC}"
        echo "$empty_files"
        return 1
    else
        echo -e "${GREEN}✅ No empty files found${NC}"
    fi
    
    # Validate file permissions
    echo -e "${YELLOW}Checking script permissions...${NC}"
    for script in scripts/*.sh; do
        if [ -f "$script" ] && [ ! -x "$script" ]; then
            echo -e "${YELLOW}⚠️  Fixing permissions for: $script${NC}"
            chmod +x "$script"
        fi
    done
    
    echo -e "${GREEN}✅ File creation safety validation completed${NC}"
}

# Function to run syntax validation
syntax_validation() {
    echo -e "\n${YELLOW}🔍 Running Syntax Validation...${NC}"
    
    # Lua syntax validation
    echo "Checking Lua files..."
    for lua_file in src/modules/*.lua src/data/*.lua scripts/*.lua; do
        if [ -f "$lua_file" ]; then
            echo "  Checking: $(basename "$lua_file")"
            lua -e "local f = loadfile('$lua_file'); if not f then print('Syntax error in $lua_file'); os.exit(1) end"
        fi
    done
    
    # Shell script syntax validation
    echo "Checking shell scripts..."
    for shell_script in scripts/*.sh; do
        if [ -f "$shell_script" ]; then
            echo "  Checking: $(basename "$shell_script")"
            bash -n "$shell_script"
        fi
    done
    
    echo -e "${GREEN}✅ Syntax validation completed${NC}"
}

# Function to run functional testing
functional_testing() {
    echo -e "\n${YELLOW}🧪 Running Functional Testing...${NC}"
    
    # Test scripts help functionality
    for script in scripts/*.sh; do
        if [ -f "$script" ] && [ -x "$script" ]; then
            script_name=$(basename "$script")
            echo "  Testing $script_name help..."
            timeout 10 "$script" --help >/dev/null 2>&1 || echo "    (no --help or different interface)"
        fi
    done
    
    # Test module loading
    echo "Testing module loading..."
    if [ -f "tests/unit/test_module_loading.lua" ]; then
        lua tests/unit/test_module_loading.lua
    else
        echo "  Module loading test not found"
    fi
    
    echo -e "${GREEN}✅ Functional testing completed${NC}"
}

# Function to validate project structure
validate_project_structure() {
    echo -e "\n${YELLOW}🏗️  Validating Project Structure...${NC}"
    
    required_dirs=("src/modules" "tests" "scripts" ".github/workflows")
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            echo -e "${RED}❌ Missing required directory: $dir${NC}"
            return 1
        else
            echo -e "${GREEN}✅ Found: $dir${NC}"
        fi
    done
    
    # Check for VS Code configuration
    if [ -f ".vscode/tasks.json" ]; then
        echo -e "${GREEN}✅ VS Code tasks configuration exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Missing VS Code tasks configuration${NC}"
    fi
    
    echo -e "${GREEN}✅ Project structure validation completed${NC}"
}

# Function to check security requirements
security_check() {
    echo -e "\n${YELLOW}🔒 Running Security Check...${NC}"
    
    # Check for .env file in .gitignore
    if [ -f ".env" ] && ! grep -q "^\.env$" .gitignore 2>/dev/null; then
        echo -e "${RED}❌ .env file exists but not in .gitignore${NC}"
        return 1
    fi
    
    # Check for potential secrets in code
    secrets_found=$(grep -r "password\|secret\|key\|token" src/ tests/ --exclude-dir=.git 2>/dev/null || true)
    if [ -n "$secrets_found" ]; then
        echo -e "${YELLOW}⚠️  Potential secrets found - please review:${NC}"
        echo "$secrets_found" | head -5
    fi
    
    # Check for template files
    if [ -f ".env.template" ]; then
        echo -e "${GREEN}✅ Environment template file exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Consider creating .env.template${NC}"
    fi
    
    echo -e "${GREEN}✅ Security check completed${NC}"
}

# Function to validate terminal completion patterns
validate_terminal_completion() {
    echo -e "\n${YELLOW}🖥️  Validating Terminal Completion Patterns...${NC}"
    
    # Check scripts for completion signaling
    scripts_with_completion=0
    total_scripts=0
    
    for script in scripts/*.sh; do
        if [ -f "$script" ]; then
            total_scripts=$((total_scripts + 1))
            if grep -q "Script completed\|SCRIPT COMPLETED\|sync\|echo.*✅" "$script"; then
                scripts_with_completion=$((scripts_with_completion + 1))
                echo -e "${GREEN}✅ $(basename "$script") has completion signaling${NC}"
            else
                echo -e "${YELLOW}⚠️  $(basename "$script") missing completion signaling${NC}"
            fi
        fi
    done
    
    if [ $total_scripts -gt 0 ]; then
        completion_ratio=$((scripts_with_completion * 100 / total_scripts))
        echo "📊 Completion signaling coverage: ${completion_ratio}%"
        
        if [ $completion_ratio -lt 50 ]; then
            echo -e "${YELLOW}💡 Consider running: scripts/enhance-script-completion.sh${NC}"
        fi
    fi
    
    echo -e "${GREEN}✅ Terminal completion validation completed${NC}"
}

# Function to check automation opportunities
check_automation_opportunities() {
    echo -e "\n${YELLOW}🔍 Checking Automation Opportunities...${NC}"
    
    # Count current automation
    vscode_tasks=$(grep -c "\"label\"" .vscode/tasks.json 2>/dev/null || echo "0")
    github_workflows=$(find .github/workflows -name "*.yml" | wc -l)
    executable_scripts=$(find scripts -name "*.sh" -executable | wc -l)
    
    echo "📊 Current Automation Status:"
    echo "  VS Code Tasks: $vscode_tasks"
    echo "  GitHub Workflows: $github_workflows"
    echo "  Executable Scripts: $executable_scripts"
    
    # Calculate automation score
    automation_score=$((vscode_tasks + github_workflows + executable_scripts))
    
    if [ $automation_score -gt 20 ]; then
        echo -e "${GREEN}✅ High automation level${NC}"
    elif [ $automation_score -gt 10 ]; then
        echo -e "${YELLOW}🔶 Moderate automation level${NC}"
    else
        echo -e "${RED}❌ Low automation level - consider adding more automation${NC}"
    fi
    
    # Check for manual processes that could be automated
    echo -e "\n💡 Potential automation opportunities:"
    
    # Check recent commits for manual indicators
    manual_commits=$(git log --oneline --since="30 days ago" | grep -i "manual\|fix\|update\|remember" | wc -l)
    if [ $manual_commits -gt 5 ]; then
        echo "  🔄 Recent commits suggest manual processes ($manual_commits commits)"
    fi
    
    # Check for missing common automations
    if [ ! -f "scripts/validate-file-creation.sh" ]; then
        echo "  📁 File creation validation could be automated"
    fi
    
    if ! grep -q "pre-commit" .git/hooks/* 2>/dev/null; then
        echo "  🪝 Pre-commit hooks could be added"
    fi
    
    if [ ! -f ".github/workflows/automated-validation.yml" ]; then
        echo "  🤖 Automated validation workflow could be added"
    fi
    
    echo -e "${GREEN}✅ Automation opportunities analysis completed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting automated validation of copilot instructions compliance...${NC}"
    
    # Run all validation functions
    validate_file_creation
    syntax_validation
    functional_testing
    validate_project_structure
    security_check
    validate_terminal_completion
    check_automation_opportunities
    
    echo -e "\n${GREEN}🎉 Copilot Instructions Automation Helper completed!${NC}"
    echo -e "${BLUE}💡 Consider running this script regularly or adding it to CI/CD${NC}"
}

# Parse command line arguments
case "${1:-all}" in
    "file-creation")
        validate_file_creation
        ;;
    "syntax")
        syntax_validation
        ;;
    "functional")
        functional_testing
        ;;
    "structure")
        validate_project_structure
        ;;
    "security")
        security_check
        ;;
    "completion")
        validate_terminal_completion
        ;;
    "automation")
        check_automation_opportunities
        ;;
    "all"|"")
        main
        ;;
    *)
        echo "Usage: $0 [file-creation|syntax|functional|structure|security|completion|automation|all]"
        echo ""
        echo "Automates validation processes mentioned in copilot instructions"
        exit 1
        ;;
esac

# Force output completion
echo ""
echo "✅ SCRIPT COMPLETED SUCCESSFULLY"
echo "$(date): Copilot automation helper finished"
sync
exit 0
