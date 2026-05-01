# ============================================================
# CSI Vertical Markets Portal — Azure Web App Deploy Script
# Subscription: e62428e7-08dd-4bc2-82e2-2c51586d9105
# Run in Azure Cloud Shell (PowerShell) or local PowerShell
# ============================================================

$SUBSCRIPTION_ID = "e62428e7-08dd-4bc2-82e2-2c51586d9105"
$RESOURCE_GROUP  = "rg-csi-portal"
$LOCATION        = "eastus"
$PLAN_NAME       = "csi-portal-plan"
$SUFFIX          = -join ((65..90) + (97..122) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
$APP_NAME        = "csi-vertical-markets-$SUFFIX"
$RUNTIME         = "NODE:20-lts"
$SKU             = "B1"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   CSI Vertical Markets Portal — Azure Deployment     ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Subscription : $SUBSCRIPTION_ID"
Write-Host "  Resource Grp : $RESOURCE_GROUP"
Write-Host "  Location     : $LOCATION"
Write-Host "  App Name     : $APP_NAME"
Write-Host ""

# Set subscription
Write-Host "▶ Setting subscription..." -ForegroundColor Yellow
az account set --subscription $SUBSCRIPTION_ID
Write-Host "  ✓ Subscription set" -ForegroundColor Green

# Resource group
Write-Host "▶ Creating resource group..." -ForegroundColor Yellow
az group create --name $RESOURCE_GROUP --location $LOCATION --output none
Write-Host "  ✓ Resource group ready" -ForegroundColor Green

# App Service plan
Write-Host "▶ Creating App Service Plan ($SKU Linux)..." -ForegroundColor Yellow
az appservice plan create `
  --name $PLAN_NAME `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --sku $SKU `
  --is-linux `
  --output none
Write-Host "  ✓ App Service Plan ready" -ForegroundColor Green

# Web App
Write-Host "▶ Creating Web App (Node 20 LTS)..." -ForegroundColor Yellow
az webapp create `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --plan $PLAN_NAME `
  --runtime $RUNTIME `
  --output none
Write-Host "  ✓ Web App created" -ForegroundColor Green

# App settings
Write-Host "▶ Configuring app settings..." -ForegroundColor Yellow
az webapp config appsettings set `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --settings NODE_ENV="production" WEBSITE_NODE_DEFAULT_VERSION="~20" SCM_DO_BUILD_DURING_DEPLOYMENT="true" `
  --output none
Write-Host "  ✓ Settings configured" -ForegroundColor Green

Write-Host "▶ Setting startup command..." -ForegroundColor Yellow
az webapp config set `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --startup-file "npm start" `
  --output none
Write-Host "  ✓ Startup command set" -ForegroundColor Green

# Deploy zip
Write-Host "▶ Deploying zip package (~60 seconds)..." -ForegroundColor Yellow
az webapp deploy `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --src-path "csi-portal-deploy.zip" `
  --type zip `
  --async false `
  --output none
Write-Host "  ✓ Deployment complete" -ForegroundColor Green

# Publish profile for GitHub Actions
Write-Host "▶ Saving publish profile for GitHub Actions..." -ForegroundColor Yellow
az webapp deployment list-publishing-profiles `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --xml | Out-File -FilePath "publish-profile.xml" -Encoding UTF8
Write-Host "  ✓ Saved to publish-profile.xml" -ForegroundColor Green

# Get URL
$APP_URL = az webapp show `
  --name $APP_NAME `
  --resource-group $RESOURCE_GROUP `
  --query "defaultHostName" `
  --output tsv

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅  DEPLOYMENT COMPLETE                            ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  🌐 Portal URL   : https://$APP_URL" -ForegroundColor Cyan
Write-Host "  📦 App Name     : $APP_NAME"
Write-Host "  📁 Resource Grp : $RESOURCE_GROUP"
Write-Host ""
Write-Host "  GitHub Secrets to add:"
Write-Host "  AZURE_WEBAPP_NAME            = $APP_NAME"
Write-Host "  AZURE_WEBAPP_PUBLISH_PROFILE = (contents of publish-profile.xml)"
