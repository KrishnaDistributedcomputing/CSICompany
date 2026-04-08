#!/bin/bash
# ============================================================
# Push CSI Portal to GitHub
# Repo: KrishnaDistributedcomputing/kvdistributedcomputing
# ============================================================

GITHUB_REPO="https://github.com/KrishnaDistributedcomputing/kvdistributedcomputing.git"

echo ""
echo "▶ Initialising git repo..."
git init

echo "▶ Setting remote to $GITHUB_REPO..."
git remote remove origin 2>/dev/null || true
git remote add origin "$GITHUB_REPO"

echo "▶ Staging all files..."
git add .

echo "▶ Committing..."
git commit -m "feat: CSI Vertical Markets Intelligence Portal

- 163 vertical markets, 1,339 mapped entities, 7 operating groups
- Deep-dive verticals: Winery, Education, SIS, Field Service, Software Dev, Clubs/Golf
- Azure Web App deployment (Node 20 LTS + Express + gzip)
- GitHub Actions CI/CD pipeline"

echo "▶ Pushing to GitHub main branch..."
git branch -M main
git push -u origin main --force

echo ""
echo "✅ Code pushed to: $GITHUB_REPO"
