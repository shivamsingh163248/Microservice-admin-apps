# 📁 Microservice Admin App — Directory & Script Setup Guide

This guide explains how to create the folder structure and required files for the **microservice-admin-app** using different methods:

* Bash Shell Script
* PowerShell Script
* Direct shell commands (Linux / Git Bash / PowerShell)

---

## 📦 Project Structure

```
microservice-admin-app/
├── backend/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/
│   ├── index.html
│   ├── register.html
│   ├── admin.html
│   ├── script.js
│   ├── style.css
│   └── Dockerfile
├── database/
│   └── init.sql
├── docker-compose.yml
└── run_all.sh
```

---

## 🐧 Bash / Ubuntu Shell Script (`create_project.sh`)

```bash
#!/bin/bash

echo "📁 Creating microservice-admin-app structure..."

mkdir -p microservice-admin-app/{backend,frontend,database}

touch microservice-admin-app/backend/{app.py,requirements.txt,Dockerfile}
touch microservice-admin-app/frontend/{index.html,register.html,admin.html,script.js,style.css,Dockerfile}
touch microservice-admin-app/database/init.sql
touch microservice-admin-app/docker-compose.yml
touch microservice-admin-app/run_all.sh

echo "✅ Project structure created successfully."
```

### 🧪 Run it via:

```bash
bash create_project.sh
```

---

## 💻 PowerShell Script (`create_project.ps1`)

```powershell
Write-Host "📁 Creating microservice-admin-app structure..."

New-Item -ItemType Directory -Path "microservice-admin-app\backend" -Force
New-Item -ItemType Directory -Path "microservice-admin-app\frontend" -Force
New-Item -ItemType Directory -Path "microservice-admin-app\database" -Force

New-Item -Path "microservice-admin-app\backend\app.py" -ItemType File
New-Item -Path "microservice-admin-app\backend\requirements.txt" -ItemType File
New-Item -Path "microservice-admin-app\backend\Dockerfile" -ItemType File

New-Item -Path "microservice-admin-app\frontend\index.html" -ItemType File
New-Item -Path "microservice-admin-app\frontend\register.html" -ItemType File
New-Item -Path "microservice-admin-app\frontend\admin.html" -ItemType File
New-Item -Path "microservice-admin-app\frontend\script.js" -ItemType File
New-Item -Path "microservice-admin-app\frontend\style.css" -ItemType File
New-Item -Path "microservice-admin-app\frontend\Dockerfile" -ItemType File

New-Item -Path "microservice-admin-app\database\init.sql" -ItemType File
New-Item -Path "microservice-admin-app\docker-compose.yml" -ItemType File
New-Item -Path "microservice-admin-app\run_all.sh" -ItemType File

Write-Host "✅ Project structure created successfully."
```

### 🧪 Run via:

```powershell
.\create_project.ps1
```

---

## 🔧 Git Bash / Ubuntu Terminal (Manual Commands)

```bash
mkdir -p microservice-admin-app/backend
mkdir -p microservice-admin-app/frontend
mkdir -p microservice-admin-app/database

touch microservice-admin-app/backend/app.py
touch microservice-admin-app/backend/requirements.txt
touch microservice-admin-app/backend/Dockerfile

touch microservice-admin-app/frontend/index.html
touch microservice-admin-app/frontend/register.html
touch microservice-admin-app/frontend/admin.html
touch microservice-admin-app/frontend/script.js
touch microservice-admin-app/frontend/style.css
touch microservice-admin-app/frontend/Dockerfile

touch microservice-admin-app/database/init.sql

touch microservice-admin-app/docker-compose.yml
touch microservice-admin-app/run_all.sh
```

✅ Just paste these one by one or all at once in Git Bash / Ubuntu terminal.

---

## 🖥️ Windows PowerShell (Manual Commands)

```powershell
New-Item -ItemType Directory -Path "microservice-admin-app\backend" -Force
New-Item -ItemType Directory -Path "microservice-admin-app\frontend" -Force
New-Item -ItemType Directory -Path "microservice-admin-app\database" -Force

New-Item -Path "microservice-admin-app\backend\app.py" -ItemType File -Force
New-Item -Path "microservice-admin-app\backend\requirements.txt" -ItemType File -Force
New-Item -Path "microservice-admin-app\backend\Dockerfile" -ItemType File -Force

New-Item -Path "microservice-admin-app\frontend\index.html" -ItemType File -Force
New-Item -Path "microservice-admin-app\frontend\register.html" -ItemType File -Force
New-Item -Path "microservice-admin-app\frontend\admin.html" -ItemType File -Force
New-Item -Path "microservice-admin-app\frontend\script.js" -ItemType File -Force
New-Item -Path "microservice-admin-app\frontend\style.css" -ItemType File -Force
New-Item -Path "microservice-admin-app\frontend\Dockerfile" -ItemType File -Force

New-Item -Path "microservice-admin-app\database\init.sql" -ItemType File -Force

New-Item -Path "microservice-admin-app\docker-compose.yml" -ItemType File -Force
New-Item -Path "microservice-admin-app\run_all.sh" -ItemType File -Force
```

✅ Paste all of these directly into PowerShell to build the project file layout.

---

Feel free to update or add more scripts, templates, or automation as needed.
