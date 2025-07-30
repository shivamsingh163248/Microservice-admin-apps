# 🔧 GitHub Actions Deployment Troubleshooting Guide

## 🚨 Common Issues & Solutions

### Issue 1: `deploy-with-ansible` job is skipped

**Problem**: The deployment job doesn't run even though the build job succeeds.

**Solutions**:
1. ✅ **Fixed**: Updated workflow condition to only run on `Ansible_Workflow` branch
2. ✅ **Fixed**: Added correct server IP to known hosts

### Issue 2: SSH Key Format Issues

**Problem**: SSH_PRIVATE_KEY secret might have formatting issues.

**Correct Format**:
```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAACFwAAAAdz...
[Your actual key content here - should be continuous lines]
...very long string of characters...
-----END OPENSSH PRIVATE KEY-----
```

**How to Fix**:
1. Open your `.pem` file in a text editor
2. Copy the ENTIRE content including `-----BEGIN` and `-----END` lines
3. Go to GitHub → Repository → Settings → Secrets and variables → Actions
4. Update `SSH_PRIVATE_KEY` with the complete key content

### Issue 3: EC2 Security Group Settings

**Required Inbound Rules**:
```
Port 22 (SSH) - Source: 0.0.0.0/0 (for GitHub Actions)
Port 8080 (Frontend) - Source: 0.0.0.0/0 (for users)
Port 5000 (Backend) - Source: 0.0.0.0/0 (optional, for API access)
```

### Issue 4: Ansible Playbook Path

**Current Configuration**: ✅ Correct
- Playbook: `ansible/deploy-production.yml`
- Inventory: `ansible/inventory.ini`
- Server: `production ansible_host=44.201.129.77`

## 🔍 Debug Steps

### Step 1: Check Workflow Status
1. Go to GitHub → Actions tab
2. Look for "Build, Push, and Deploy Microservices" workflow
3. Check if both jobs run:
   - ✅ `build-and-push` (should complete)
   - ✅ `deploy-with-ansible` (should NOT be skipped)

### Step 2: Test SSH Connection Manually
```bash
# Test SSH connection to your server
ssh -i your-key.pem ubuntu@44.201.129.77

# If successful, you should see Ubuntu login
```

### Step 3: Check GitHub Secrets
1. Go to Repository → Settings → Secrets and variables → Actions
2. Verify `SSH_PRIVATE_KEY` exists and has the complete key content

### Step 4: Check Workflow Logs
Look for these in the GitHub Actions logs:
- ✅ "Setup SSH" step should succeed
- ✅ "Add Known Hosts" step should add 44.201.129.77
- ✅ "Verify Ansible Inventory" step should ping the server
- ✅ "Run Ansible Playbook" step should deploy

## 🎯 Expected Workflow Execution

### When you push to `Ansible_Workflow` branch:

1. **Build Job** (2-3 minutes):
   - ✅ Build Docker images
   - ✅ Push to GitHub Container Registry
   - ✅ Update docker-compose files
   - ✅ Commit changes

2. **Deploy Job** (3-5 minutes):
   - ✅ Setup SSH connection
   - ✅ Install Ansible
   - ✅ Connect to 44.201.129.77
   - ✅ Deploy containers
   - ✅ Verify deployment

## 🔧 Quick Fixes

### If SSH Key is Wrong:
1. Generate a new key pair:
   ```bash
   ssh-keygen -t rsa -b 4096 -f aws-key
   ```
2. Add public key to EC2 instance
3. Add private key to GitHub Secrets

### If Deploy Job is Still Skipped:
Check the workflow file trigger:
```yaml
on:
  push:
    branches: [ Ansible_Workflow ]  # ✅ Correct
```

### If Ansible Connection Fails:
1. Check EC2 instance is running
2. Verify security group allows SSH (port 22)
3. Ensure SSH key has correct permissions

## 🎉 Success Indicators

After successful deployment, you should see:
- ✅ GitHub Actions shows green checkmarks for both jobs
- ✅ Application accessible at: http://44.201.129.77:8080
- ✅ Backend API at: http://44.201.129.77:5000/health
- ✅ Ansible playbook reports "SUCCESS ✅"

## 📋 Next Action Items

1. **Test the updated workflow** by pushing a commit
2. **Check GitHub Actions logs** if deploy job still skips
3. **Verify SSH key format** in GitHub Secrets
4. **Test manual SSH connection** to 44.201.129.77

The workflow should now run correctly on the `Ansible_Workflow` branch! 🚀
