#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/electron/website"
BRANCH="main"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
    echo "[INFO] Cloning ${REPO_URL}..."
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
else
    echo "[INFO] source-repo already exists, skipping clone."
fi

cd "$REPO_DIR"

# --- Node version ---
# electron/website requires Node 22 (engines field)
echo "[INFO] Installing Node 22..."
sudo n 22
echo "[INFO] Using Node $(node --version)"

# --- Package manager: Yarn 4 via corepack ---
# electron/website uses packageManager: yarn@4.x
echo "[INFO] Enabling corepack for Yarn 4..."
corepack enable yarn
echo "[INFO] Yarn version: $(yarn --version)"

# --- Dependencies ---
echo "[INFO] Installing dependencies..."
yarn install

# --- Pre-build: downloads Electron docs from GitHub into docs/latest/ ---
# GH_TOKEN is recommended to avoid GitHub API rate limits
echo "[INFO] Running pre-build (downloads Electron docs)..."
if [ -z "${GH_TOKEN:-}" ]; then
    echo "[WARN] GH_TOKEN is not set. GitHub API rate limits may cause pre-build to fail."
fi
yarn pre-build

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
    echo "[INFO] Applying content fixes..."
    node -e "
    const fs = require('fs');
    const path = require('path');
    const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
    for (const [file, ops] of Object.entries(fixes.fixes || {})) {
        if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
        let content = fs.readFileSync(file, 'utf8');
        for (const op of ops) {
            if (op.type === 'replace' && content.includes(op.find)) {
                content = content.split(op.find).join(op.replace || '');
                console.log('  fixed:', file, '-', op.comment || '');
            }
        }
        fs.writeFileSync(file, content);
    }
    for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
        const c = typeof cfg === 'string' ? cfg : cfg.content;
        fs.mkdirSync(path.dirname(file), {recursive: true});
        fs.writeFileSync(file, c);
        console.log('  created:', file);
    }
    "
fi

echo "[DONE] Repository is ready for docusaurus commands."
