# CSI Vertical Markets Intelligence Portal

Constellation Software Inc. — comprehensive research portal covering **163 vertical markets**, **7 operating groups** and **1,339+ mapped entities** across 100+ countries.

Deep-dive verticals: Winery Management, Education, Student Information Systems, Field Service, Software Development, Private Clubs & Golf, and more.

---

## 🚀 Deploy to Azure Web App (Step-by-Step)

### Prerequisites
- Azure account with an active subscription
- Azure CLI installed (`az` command), or use the Azure Portal
- This repo pushed to GitHub (KrishnaDistributedcomputing/kvdistributedcomputing)

---

### Step 1 — Create the Azure Web App

#### Option A: Azure Portal (no CLI needed)
1. Go to [portal.azure.com](https://portal.azure.com)
2. Click **Create a resource → Web App**
3. Fill in:
   - **Resource Group**: Create new → `rg-csi-portal`
   - **Name**: `csi-vertical-markets` (or any unique name — this becomes your URL: `https://csi-vertical-markets.azurewebsites.net`)
   - **Runtime stack**: `Node 20 LTS`
   - **Operating System**: `Linux`
   - **Region**: `East US` (or your preferred region)
   - **Pricing plan**: `Free F1` is fine for personal use; `B1 Basic` for production
4. Click **Review + create → Create**

#### Option B: Azure CLI
```bash
# Login
az login

# Create resource group
az group create --name rg-csi-portal --location eastus

# Create App Service plan (free tier)
az appservice plan create \
  --name csi-portal-plan \
  --resource-group rg-csi-portal \
  --sku F1 \
  --is-linux

# Create the Web App
az webapp create \
  --name csi-vertical-markets \
  --resource-group rg-csi-portal \
  --plan csi-portal-plan \
  --runtime "NODE:20-lts"
```

---

### Step 2 — Get the Publish Profile

1. In Azure Portal, go to your Web App
2. Click **Download publish profile** (in the Overview pane)
3. Save the `.PublishSettings` file — you'll need its contents in the next step

---

### Step 3 — Add GitHub Secrets

In your GitHub repo (`KrishnaDistributedcomputing/kvdistributedcomputing`):

1. Go to **Settings → Secrets and variables → Actions → New repository secret**
2. Add these two secrets:

| Secret Name | Value |
|---|---|
| `AZURE_WEBAPP_NAME` | Your web app name (e.g., `csi-vertical-markets`) |
| `AZURE_WEBAPP_PUBLISH_PROFILE` | Paste the **entire contents** of the `.PublishSettings` file you downloaded |

---

### Step 4 — Push to GitHub & Deploy

```bash
# If you haven't already initialised git:
git init
git remote add origin https://github.com/KrishnaDistributedcomputing/kvdistributedcomputing.git

# Add all files and push to main
git add .
git commit -m "Initial deploy: CSI Vertical Markets Portal"
git push -u origin main
```

The GitHub Actions workflow (`.github/workflows/deploy.yml`) will trigger automatically on every push to `main`. Watch it run under **Actions** tab in GitHub.

Your portal will be live at:
```
https://<your-app-name>.azurewebsites.net
```

---

### Step 5 — Verify

Open the URL in your browser. First load may take 10–15 seconds on the Free tier (cold start). The portal is a ~3.2MB self-contained HTML file; gzip compression is enabled in `server.js` so it transfers as ~400–500KB.

---

## 📁 Project Structure

```
kvdistributedcomputing/
├── index.html                  # The full CSI portal (self-contained, ~3.2MB)
├── CSI_Verticals_Data.json     # Master dataset (163 verticals, 1,339 entities)
├── server.js                   # Express server (gzip, caching, SPA fallback)
├── package.json                # Node.js dependencies
├── web.config                  # Azure IIS/iisnode configuration
├── .gitignore
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions → Azure Web App CI/CD
└── README.md
```

---

## 🔄 Updating the Portal

Whenever the portal HTML is regenerated:
1. Replace `index.html` with the new version
2. Replace `CSI_Verticals_Data.json` with the updated dataset
3. Commit and push to `main` — GitHub Actions deploys automatically

---

## 🛠 Local Development

```bash
npm install
npm start
# Open http://localhost:3000
```

---

## Portal Contents

| Metric | Value |
|---|---|
| Vertical markets | 163 |
| Mapped entities | 1,339 |
| Operating groups | 7 (Jonas, Volaris, Harris, Vela, Topicus, Lumine, Perseus) |
| Countries | 54 |
| Deep-dive verticals | Winery, Education, SIS, Field Service, Software Dev, Clubs/Golf |

Deep-dive verticals include: full market intelligence, jargon glossaries, CSI strategic analysis, Market Intelligence SP cards with customer quotes and ratings, and 15 AI/Azure use cases per vertical.
