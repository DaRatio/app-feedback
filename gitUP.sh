#!/bin/bash
# gitUP.sh — Universal safe commit + push script for any Git repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}[1/5] Fetching latest remote state...${NC}"
git fetch origin

# ── Detect default branch ─────────────────────────────────────────────────
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')

if [ -z "$DEFAULT_BRANCH" ]; then
    echo -e "${RED}ERROR: Unable to detect default branch.${NC}"
    exit 1
fi

echo -e "${CYAN}Default branch detected: ${DEFAULT_BRANCH}${NC}"

# ── Pull + rebase with autostash ──────────────────────────────────────────
echo -e "${CYAN}[2/5] Pulling and rebasing (with auto-stash)...${NC}"

if ! git pull --rebase --autostash origin "$DEFAULT_BRANCH"; then
    echo ""
    echo -e "${RED}Pull/rebase failed (likely conflicts).${NC}"
    echo -e "${YELLOW}Resolve conflicts, then run:${NC}"
    echo "  git add <files>"
    echo "  git rebase --continue"
    echo ""
    echo -e "${CYAN}Your stashed changes are safe:${NC}"
    echo "  git stash list"
    exit 1
fi

# ── Stage changes ─────────────────────────────────────────────────────────
echo -e "${CYAN}[3/5] Staging all changes...${NC}"
git add -A

echo -e "${CYAN}[4/5] Checking for staged changes...${NC}"
if git diff --cached --quiet; then
    echo -e "${GREEN}No changes to commit. Nothing to push.${NC}"
    exit 0
fi

# ── Commit ────────────────────────────────────────────────────────────────
echo -e "${CYAN}Creating commit...${NC}"
git commit -m "Update on $(date +"%Y-%m-%d %H:%M:%S")"

# ── Push ──────────────────────────────────────────────────────────────────
echo -e "${CYAN}[5/5] Pushing to origin/${DEFAULT_BRANCH}...${NC}"
git push origin "$DEFAULT_BRANCH"

echo -e "${GREEN}Done.${NC}"
