#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/electron/website"
REPO_DIR="source-repo"

# Install Node 22 (required by electron/website engines field)
echo "Installing Node 22..."
sudo n 22

# Verify node version
node --version

# Clone repository
echo "Cloning ${REPO_URL}..."
git clone --depth 1 "${REPO_URL}" "${REPO_DIR}"
cd "${REPO_DIR}"

# Enable corepack for Yarn 4 (packageManager: yarn@4.10.3)
echo "Enabling corepack..."
corepack enable yarn

# Verify yarn version
yarn --version

# Install dependencies
echo "Installing dependencies..."
yarn install

# Run write-translations
echo "Running write-translations..."
yarn write-translations

echo "SUCCESS: write-translations completed"
