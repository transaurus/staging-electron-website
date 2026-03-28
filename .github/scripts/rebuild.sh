#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for electron/website
# Runs on existing source tree (no clone). Installs deps, runs pre-build, builds.

# --- Node version ---
# electron/website requires Node 22 (engines field)
echo "[INFO] Installing Node 22..."
sudo n 22
echo "[INFO] Using Node $(node --version)"

# --- Package manager: Yarn 4 via corepack ---
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

# --- Build ---
echo "[INFO] Running docusaurus build..."
yarn build

echo "[DONE] Build complete."
