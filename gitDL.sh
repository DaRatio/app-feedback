#!/bin/bash
# gitDL.sh — Universal safe pull script for any Git repo
#
# Usage:
#   ./gitDL.sh                # Pull latest changes
#   ./gitDL.sh --skip-restart # (Optional) placeholder hook for service restart

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

SKIP_RESTART=false
for arg in "$@"; do
    case $arg in
        --skip-restart) SKIP_RESTART=true ;;
    esac
done

# ═══════════════════════════════════════════════════════════════════════════
# Step 1: Detect default branch
# ═══════════════════════════════════════════════════════════════════════════
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

if [ -z "$DEFAULT_BRANCH" ]; then
    echo -e "${RED}Unable to detect default branch.${NC}"
    exit 1
fi

echo -e "${CYAN}Default branch detected: ${DEFAULT_BRANCH}${NC}"

# ═══════════════════════════════════════════════════════════════════════════
# Step 2: Intelligent safe pull logic
# ═══════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[1/2] Pulling latest code...${NC}"
git fetch origin

# ── CASE 1: No local commits (HEAD missing) ────────────────────────────────
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo -e "${YELLOW}No local commits detected (HEAD missing).${NC}"

    if git rev-parse --verify "origin/$DEFAULT_BRANCH" >/dev/null 2>&1; then
        echo -e "${CYAN}Initializing local branch from origin/$DEFAULT_BRANCH...${NC}"
        git checkout -B "$DEFAULT_BRANCH" "origin/$DEFAULT_BRANCH"
        echo -e "${GREEN}Repository initialized and synced.${NC}"
        exit 0
    else
        echo -e "${YELLOW}Remote branch has no commits either. Nothing to pull.${NC}"
        exit 0
    fi
fi

# ── CASE 2: Normal repo with commits ───────────────────────────────────────
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$DEFAULT_BRANCH" 2>/dev/null || echo "none")
BASE=$(git merge-base HEAD "origin/$DEFAULT_BRANCH" 2>/dev/null || echo "none")

# Remote has no commits
if [ "$REMOTE" = "none" ]; then
    echo -e "${YELLOW}Remote branch has no commits. Nothing to pull.${NC}"
    exit 0
fi

# ── CASE 2A: Already up to date ────────────────────────────────────────────
if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}Already up to date.${NC}"
    exit 0
fi

# ── CASE 2B: Fast-forward possible ─────────────────────────────────────────
if [ "$LOCAL" = "$BASE" ]; then
    BEFORE_SHA="$LOCAL"
    git merge --ff-only "origin/$DEFAULT_BRANCH"
    AFTER_SHA=$(git rev-parse HEAD)

    if [ "$BEFORE_SHA" = "$AFTER_SHA" ]; then
        echo -e "${GREEN}Already up to date.${NC}"
    else
        COMMITS=$(git rev-list --count "${BEFORE_SHA}".."${AFTER_SHA}")
        echo -e "${GREEN}Pulled ${COMMITS} new commit(s).${NC}"
    fi
    exit 0
fi

# ── CASE 2C: Local ahead of remote ─────────────────────────────────────────
if [ "$REMOTE" = "$BASE" ]; then
    echo -e "${YELLOW}Local branch is ahead of remote. No pull needed.${NC}"
    exit 0
fi

# ── CASE 2D: Diverged ──────────────────────────────────────────────────────
echo -e "${YELLOW}Local and remote branches have diverged.${NC}"
echo -e "${CYAN}Attempting safe auto-rebase...${NC}"

if git rebase "origin/$DEFAULT_BRANCH"; then
    echo -e "${GREEN}Rebase successful.${NC}"
    exit 0
else
    echo -e "${RED}Auto-rebase failed. Leaving repo unchanged.${NC}"
    git rebase --abort || true
    exit 1
fi

echo ""
# ═══════════════════════════════════════════════════════════════════════════
# Step 3: Optional restart hook (commented by default)
# ═══════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[2/2] Optional restart hook...${NC}"

if [ "$SKIP_RESTART" = false ]; then
    # PLACEHOLDER: Add repo-specific restart logic here
    :
fi
