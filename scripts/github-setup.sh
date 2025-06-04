#!/bin/bash
# GitHub Repository Setup Script
# This script provides instructions and commands for setting up the GitHub repository

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}==================================${NC}"
echo -e "${CYAN}GitHub Repository Setup Instructions${NC}"
echo -e "${CYAN}==================================${NC}"
echo

echo -e "${YELLOW}Step 1: Create GitHub Repository${NC}"
echo "1. Go to https://github.com/new"
echo "2. Repository name: gotemplaterepo"
echo "3. Description: Production-ready Go project template with Clean Architecture"
echo "4. Set as Public (or Private if you prefer)"
echo "5. DO NOT initialize with README, .gitignore, or license"
echo "6. Click 'Create repository'"
echo
echo -e "${GREEN}Press Enter when you've created the repository...${NC}"
read -r

echo -e "${YELLOW}Step 2: Configure Git${NC}"
echo "Running the following commands:"
echo

# Configure git (if not already configured)
if [[ -z "$(git config --global user.email)" ]]; then
    echo -e "${BLUE}Setting up git config...${NC}"
    echo "git config --global user.email \"your-email@example.com\""
    echo "git config --global user.name \"Your Name\""
    echo
    echo -e "${YELLOW}Please run these commands with your information, then re-run this script${NC}"
    exit 1
fi

# Initialize git repository if not already initialized
if [[ ! -d .git ]]; then
    echo -e "${BLUE}Initializing git repository...${NC}"
    git init
fi

# Add all files
echo -e "${BLUE}Adding all files...${NC}"
git add -A

# Create initial commit
echo -e "${BLUE}Creating initial commit...${NC}"
git commit -m "feat: initial commit - Go Clean Architecture template

- Clean Architecture with SOLID principles
- Template instantiation and synchronization
- Semantic versioning with conventional commits
- Comprehensive test suite
- Docker and CI/CD support
- Pre-commit hooks and code quality tools
- Documentation and examples"

# Add remote
echo
echo -e "${YELLOW}Step 3: Add Remote Repository${NC}"
echo "Enter your GitHub username (default: jmcarbo):"
read -r GITHUB_USERNAME
GITHUB_USERNAME=${GITHUB_USERNAME:-jmcarbo}

echo "Enter repository name (default: gotemplate):"
read -r REPO_NAME
REPO_NAME=${REPO_NAME:-gotemplate}

echo
echo -e "${BLUE}Adding remote...${NC}"
git remote add origin "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

# Create main branch
echo -e "${BLUE}Setting up main branch...${NC}"
git branch -M main

# Push to GitHub
echo
echo -e "${YELLOW}Step 4: Push to GitHub${NC}"
echo -e "${BLUE}Pushing to GitHub...${NC}"
git push -u origin main

echo
echo -e "${GREEN}✅ Success! Your repository is now on GitHub.${NC}"
echo
echo -e "${CYAN}Next steps:${NC}"
echo "1. Visit https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo "2. Add topics: go, template, clean-architecture, solid, golang"
echo "3. Update the repository description"
echo "4. Enable 'Template repository' in Settings"
echo "5. Enable GitHub Actions in the repository settings"
echo "6. Set up branch protection rules for 'main' branch"
echo
echo -e "${CYAN}To use this template for new projects:${NC}"
echo "1. Click 'Use this template' button on GitHub"
echo "2. Or clone and run: make setup-project PROJECT_NAME=myapp MODULE_PATH=github.com/user/myapp"
echo
echo -e "${CYAN}Repository URL:${NC} https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"