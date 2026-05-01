#!/bin/bash
# ============================================================
# CSI Vertical Markets Portal — Azure Web App Deploy Script
# Subscription: e62428e7-08dd-4bc2-82e2-2c51586d9105
# Run this in Azure Cloud Shell: https://shell.azure.com
# ============================================================

set -e

# ── Config ────────────────────────────────────────────────────
SUBSCRIPTION_ID="e62428e7-08dd-4bc2-82e2-2c51586d9105"
RESOURCE_GROUP="rg-csi-portal"
LOCATION="eastus"
PLAN_NAME="csi-portal-plan"
APP_NAME="csi-vertical-markets-$(openssl rand -hex 3)"   # unique suffix
RUNTIME="NODE:20-lts"
SKU="B1"   # Basic — supports custom domains & always-on; use F1 for free tier

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   CSI Vertical Markets Portal — Azure Deployment     ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  Subscription : $SUBSCRIPTION_ID"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location      : $LOCATION"
echo "  App Name      : $APP_NAME"
echo "  Runtime       : $RUNTIME"
echo "  SKU           : $SKU"
echo ""

# ── Set subscription ──────────────────────────────────────────
echo "▶ Setting subscription..."
az account set --subscription "$SUBSCRIPTION_ID"
echo "  ✓ Subscription set"

# ── Resource Group ────────────────────────────────────────────
echo "▶ Creating resource group '$RESOURCE_GROUP' in $LOCATION..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none
echo "  ✓ Resource group ready"

# ── App Service Plan ──────────────────────────────────────────
echo "▶ Creating App Service Plan '$PLAN_NAME' ($SKU, Linux)..."
az appservice plan create \
  --name "$PLAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku "$SKU" \
  --is-linux \
  --output none
echo "  ✓ App Service Plan ready"

# ── Web App ───────────────────────────────────────────────────
echo "▶ Creating Web App '$APP_NAME' (Node 20 LTS)..."
az webapp create \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$PLAN_NAME" \
  --runtime "$RUNTIME" \
  --output none
echo "  ✓ Web App created"

# ── App Settings ──────────────────────────────────────────────
echo "▶ Configuring app settings..."
az webapp config appsettings set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --settings \
    NODE_ENV="production" \
    WEBSITE_NODE_DEFAULT_VERSION="~20" \
    SCM_DO_BUILD_DURING_DEPLOYMENT="true" \
  --output none
echo "  ✓ App settings configured"

echo "▶ Setting startup command..."
az webapp config set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --startup-file "npm start" \
  --output none
echo "  ✓ Startup command set"

# ── Build the zip if not present ─────────────────────────────
if [ ! -f "csi-portal-deploy.zip" ]; then
  echo "▶ Building deployment zip..."
  if [ ! -f "index.html" ]; then
    echo "  ✗ ERROR: index.html not found."
    echo "    Upload your files first:"
    echo "    - index.html (the CSI portal)"
    echo "    - CSI_Verticals_Data.json"
    echo "    - server.js, package.json, web.config"
    exit 1
  fi
  zip -r csi-portal-deploy.zip \
    index.html \
    CSI_Verticals_Data.json \
    server.js \
    package.json \
    package-lock.json \
    web.config \
    .gitignore \
    README.md \
    2>/dev/null || true
  echo "  ✓ Zip built"
fi

# ── Deploy ────────────────────────────────────────────────────
echo "▶ Deploying zip to Azure (this takes ~60 seconds)..."
az webapp deploy \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --src-path "csi-portal-deploy.zip" \
  --type zip \
  --async false \
  --output none
echo "  ✓ Deployment complete"

# ── Get publish profile for GitHub Actions ───────────────────
echo "▶ Fetching publish profile for GitHub Actions setup..."
az webapp deployment list-publishing-profiles \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --xml \
  > publish-profile.xml
echo "  ✓ Saved to publish-profile.xml"

# ── Output ────────────────────────────────────────────────────
APP_URL=$(az webapp show \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "defaultHostName" \
  --output tsv)

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   ✅  DEPLOYMENT COMPLETE                            ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "  🌐 Portal URL  : https://$APP_URL"
echo "  📦 App Name    : $APP_NAME"
echo "  📁 Resource Grp: $RESOURCE_GROUP"
echo ""
echo "  Next steps:"
echo "  1. Open https://$APP_URL in your browser"
echo "  2. For GitHub CI/CD, add these secrets to your repo:"
echo "     AZURE_WEBAPP_NAME          = $APP_NAME"
echo "     AZURE_WEBAPP_PUBLISH_PROFILE = (contents of publish-profile.xml)"
echo ""
echo "  Save your app name: $APP_NAME"
