#!/bin/bash

# CodePath Open Source Bootstrap Script
# This script automatically forks several open source repositories for educational purposes

set -e  # Exit on any error

# Repositories to fork (hardcoded for simplicity)
REPOSITORIES=(
    "codepath/puter"
    "codepath/chatbox" 
    "codepath/dokploy"
    "codepath/scalar"
    "codepath/omi"
    "codepath/superset"
)

# Parse command line arguments (only help)
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "CodePath Open Source Bootstrap Script"
            echo "Usage: $0"
            echo ""
            echo "This script will automatically:"
            echo "  - Fork multiple open source repositories to your GitHub account"
            echo "  - Enable issues on each forked repository"
            echo ""
            echo "Repositories that will be forked:"
            for repo in "${REPOSITORIES[@]}"; do
                echo "  - https://github.com/$repo"
            done
            echo ""
            echo "No arguments needed - just run the script!"
            exit 0
            ;;
        *)
            echo "Error: This script doesn't accept arguments"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "CodePath Open Source Bootstrap Script"
echo "=" | tr -c '\n' '=' | head -c 50; echo
echo "Repositories to fork: ${#REPOSITORIES[@]}"
for repo in "${REPOSITORIES[@]}"; do
    echo "  - $repo"
done
echo

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    echo ""
    echo "Install instructions:"
    echo "  Ubuntu/Debian: sudo apt install gh"
    echo "  macOS:         brew install gh"
    echo "  Other:         https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
echo "🔑 Step 1: GitHub Authentication Required"
echo "For security, please authenticate with GitHub CLI..."

# Force logout any existing session
gh auth logout --hostname github.com 2>/dev/null || true

echo "Please login with your GitHub account:"
if ! gh auth login --hostname github.com --git-protocol https --web --skip-ssh-key; then
    echo "Authentication failed"
    exit 1
fi

# Verify authentication worked
if ! gh auth status &> /dev/null; then
    echo "Authentication verification failed"
    exit 1
fi

# Get current user
CURRENT_USER=$(gh api user --jq '.login')
echo "✅ Authenticated as: $CURRENT_USER"
echo ""

# Function to process a single repository
process_repository() {
    local REPO="$1"
    local REPO_NUMBER="$2"
    local TOTAL_REPOS="$3"
    
    echo ""
    echo "🚀 Processing repository $REPO_NUMBER/$TOTAL_REPOS: $REPO"
    echo "=" | tr -c '\n' '=' | head -c 60; echo
    
    # Extract owner and repo name
    IFS='/' read -r OWNER REPO_NAME <<< "$REPO"
    
    # Validate repository format
    if [[ -z "$OWNER" || -z "$REPO_NAME" ]]; then
        echo "❌ Error: Invalid repository format for $REPO"
        return 1
    fi
    
    # Check if trying to fork own repository
    if [[ "$OWNER" == "$CURRENT_USER" ]]; then
        echo "⚠️  Skipping $REPO (cannot fork your own repository)"
        return 0
    fi
    
    # Use original repo name for the fork
    FORK_NAME="$REPO_NAME"
    FORK_REPO="$CURRENT_USER/$FORK_NAME"

    # Step 2: Fork the repository
    echo ""
    echo "Step 2: Setting up repository..."

    # Check if target repository already exists
    if gh repo view "$FORK_REPO" &> /dev/null; then
        echo "ℹ️  Repository already exists: $FORK_REPO"
        echo "✅ Using existing repository"
    else
        echo "🔄 Forking repository..."
        
        # Fork the repository first
        if gh repo fork "$REPO" --clone=false > /dev/null 2>&1; then
            echo "✅ Fork created as $FORK_REPO"
            
            # Wait a moment for changes to propagate
            sleep 2
        else
            echo "❌ Failed to fork repository"
            echo "This could be due to:"
            echo "  - Repository doesn't exist or is private"
            echo "  - You don't have permission to fork it"
            echo "  - Network connectivity issues"
            return 1
        fi
    fi

    # Step 3: Using default branch
    echo ""
    echo "Step 3: Using default branch from source repository..."

    # Step 4: Enable issues
    echo ""
    echo "📋 Step 4: Enabling issues..."
    if gh api "repos/$FORK_REPO" -X PATCH -f has_issues=true > /dev/null 2>&1; then
        echo "✅ Issues enabled successfully"
    else
        echo "⚠️  Warning: Could not enable issues"
    fi
    
    # Repository summary
    echo ""
    echo "✅ Repository $REPO completed!"
    echo "📁 Your fork: https://github.com/$FORK_REPO"
}

# Main execution: Process all repositories
TOTAL_REPOS=${#REPOSITORIES[@]}
SUCCESSFUL_FORKS=0
FAILED_FORKS=0

for i in "${!REPOSITORIES[@]}"; do
    if process_repository "${REPOSITORIES[$i]}" "$((i+1))" "$TOTAL_REPOS"; then
        # ((SUCCESSFUL_FORKS++))
        SUCCESSFUL_FORKS=$((SUCCESSFUL_FORKS + 1))
    else
        # ((FAILED_FORKS++))
        FAILED_FORKS=$((FAILED_FORKS + 1))
        echo "❌ Failed to process ${REPOSITORIES[$i]}"
    fi
done

# Final summary
echo ""
echo ""
echo "🎉 All done! Summary:"
echo "=" | tr -c '\n' '=' | head -c 50; echo
echo "✅ Successfully forked: $SUCCESSFUL_FORKS repositories"
if [[ $FAILED_FORKS -gt 0 ]]; then
    echo "❌ Failed to fork: $FAILED_FORKS repositories"
fi

echo ""
echo "📁 Your forked repositories:"
for repo in "${REPOSITORIES[@]}"; do
    IFS='/' read -r OWNER REPO_NAME <<< "$repo"
    if [[ "$OWNER" != "$CURRENT_USER" ]]; then
        echo "  - https://github.com/$CURRENT_USER/$REPO_NAME"
    fi
done

echo ""
echo "💡 Next steps:"
echo "  - View your repositories: https://github.com/$CURRENT_USER?tab=repositories"
echo "  - Clone a repository: git clone git@github.com:$CURRENT_USER/REPO_NAME"
echo "  - Start exploring and contributing to the repositories!"