# 🔑 SSH Key Setup Guide for GitHub Actions & AWS EC2

## 🎯 Current Situation

Your RSA private key is **CORRECT** for AWS EC2! The issue is that GitHub Actions needs it configured properly.

## 📋 Step-by-Step Solution

### Step 1: Copy Your Private Key to GitHub Secrets

1. **Go to your GitHub repository**: 
   `https://github.com/shivamsingh163248/Microservice-admin-apps`

2. **Navigate to Settings**:
   - Click "Settings" tab
   - Click "Secrets and variables" → "Actions"

3. **Add/Update SSH_PRIVATE_KEY**:
   - Click "New repository secret" or "Update" if it exists
   - Name: `SSH_PRIVATE_KEY`
   - Value: **Copy and paste your ENTIRE key exactly as shown below:**

```
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAsUvxDRJa8Ejiatw2ThdcEIEK5BR786pobRrXWbsS0HD5PHnP
/GlZACNcefDmDqZlQQuaEo7O/dVod5QXbc5rFMG0szmQqhbW/7rXrw/s7gAwFCFO
qTzN1lTsUfNgt/jNpGlV7BTPzxqaZNEmUuhIH2Z+TqvgBb+lJNbw9E8BOYbsx12v
fGmPJbah6Kdzs8Qdqp96vmsacBoATiE0f4E5AKsDj/gO5PAbSb22koQdTEfKLTGy
QepCBctnLJW2Bj6Vy6GXZEtOE4bMxYi5aQpZCRR5i5Eyzj9gLroJQIl5r9yL8GEy
gEmBe5QXVQJbLbr7JoHqSbYaI4/nmnoVCMkk3QIDAQABAoIBAQCW3xHUVs9N9CfA
WX5Yu6YbYUQ8THYiJtvQJGwnLntXJxvga6Qinh8fb/fsyKNsygoV7OKCckYQWP8Z
6sp5JZOXyTKU5SKGqwLwATYzAbFT4pMHPkSq3VQn1IJ5RksCotWT2BNG33rrOS8z
JYugN4vQNK69EaOEIM5OaB4JOAXJxe2zZnQ+CSiriYEWKs9NBIUgVSw1H7wD+wZB
s1OaENrVU8iPnwnFrAY8SrxQTSCmPk6cGPa5x8s4mfjAN3NLQZSzzPDLHjuxm6yf
Lf7uBVHLz7iCzyxA2dZsx5U5QQHMIm9gD+WNbNCc/umuiE65f0pdAu5+oo3/fs83
9+zIzrKdAoGBANcBn3/3YCKE0LdFuU/PkxtXGNTSnxWeZVTY0HBfytUSud6OB99L
B07jQpePHybxnLjqe30jDeGQVtUijdVmxCvWkp+FH8hqdTiL6ZFVNis0a4EVbfor
G0wqHtA9Wm2oidnwgMtobpwtyI9uesCQLK0peOJkPzGRt9Es/H9Wp8evAoGBANMZ
uRB9vH2+JtXPvLyO+N90Nmt8AOUDiwsSfKOw74p0ntN57ElzbLipCWkUH83bNTJd
S+eYVn1ZR2BwfvaAgfAMmXh3R+Cty4iZLlo6I4wZClJOZUpBRiIBr9QuZqeH94dB
oLCyvKGbJ25x5KicxCn9SVEKi5NzSqCvlih5U7MzAoGBAM9ecGCyzdTdNpTdOash
cCe5bGivr+HhAKjB6N/JdE7nnb9qS2tw6N6MUEjvMEOWWur6tRnvek7osOcmSZfe
YyxI6ufSNOJO0zozr5WNkw4+o8U/TvAvLUfbhBaiZhpHqJU74mzND4mwmrTEAL7D
D2QAEOiBeXWsrpagBfQnNvFfAoGACt4yJuUyRQ77FNrjDpoVuftTqejyatfp2qIT
BKJhUrF6U8zdG1Lz7/XT5DMDCCgW7wbal4vCOCXWhOKFxs8K4X7kj80kSC7qYZfx
SPfhSJ8pZt9eW5pMsAeCM9xHsKxRVAdO7InnKDLCru7yJLQdbUP6+E8grHCtEOS5
SFAmvP0CgYEAm3B5SRJVdit+/+1p+sd4oYPPV15CO+aJVy88qJNQr8+mwO/yq4Ry
EdUNIjotpQcYeKiuRj27JQWmMEAHTLbsuF4dWDLIfPztEe2gTiguV+PnQuGPxRkJ
4osrPWhm/Me4MmczujlAr1snQF9nyemQtTQ9XciCHNQYy5MrYqfaMG0=
-----END RSA PRIVATE KEY-----
```

**⚠️ IMPORTANT**: 
- Include the `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines
- Do NOT add any extra spaces or line breaks
- Copy the ENTIRE text block exactly as shown above

### Step 2: Verify EC2 Key Pair Configuration

Your key is already correctly configured for EC2! This is the key AWS generated for your instance.

**✅ Your key setup is correct for:**
- EC2 instance access
- Ansible SSH connections
- Automated deployments

### Step 3: Verify EC2 Security Group

Make sure your EC2 Security Group allows:

```
Inbound Rules:
- SSH (Port 22) from 0.0.0.0/0 (for GitHub Actions)
- HTTP (Port 8080) from 0.0.0.0/0 (for your app)
- Custom TCP (Port 5000) from 0.0.0.0/0 (for backend API)
```

### Step 4: Test the Updated Workflow

I've updated your workflow to handle RSA keys better. Now test it:

1. **Commit and push** the workflow changes:
```bash
git add .
git commit -m "Fix SSH key handling in workflow"
git push origin Ansible_Workflow
```

2. **Monitor GitHub Actions**:
   - Go to Actions tab in your repo
   - Watch for "Build, Push, and Deploy Microservices"
   - Both jobs should now run successfully

## 🔍 What Changed in the Workflow

**Before** (using webfactory/ssh-agent):
```yaml
- name: Setup SSH
  uses: webfactory/ssh-agent@v0.8.0
  with:
    ssh-private-key: ${{ secrets.SSH_PRIVATE_KEY }}
```

**After** (manual SSH setup):
```yaml
- name: Setup SSH
  run: |
    mkdir -p ~/.ssh
    echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    eval $(ssh-agent -s)
    ssh-add ~/.ssh/id_rsa
```

This approach works better with traditional RSA keys from AWS.

## 🎉 Expected Results

After the fix:
- ✅ `deploy-with-ansible` job will run (not skip)
- ✅ SSH connection to 44.201.129.77 will succeed
- ✅ Ansible playbook will deploy your services
- ✅ App will be accessible at http://44.201.129.77:8080

## 📱 Alternative: Create New OpenSSH Key (Optional)

If you want to create a new key in OpenSSH format:

### On your local machine:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-openssh-key -m OpenSSH
```

### Add public key to EC2:
1. Copy content of `~/.ssh/aws-openssh-key.pub`
2. Add to EC2 instance: `~/.ssh/authorized_keys`

### Use private key in GitHub:
1. Copy content of `~/.ssh/aws-openssh-key` 
2. Add to GitHub Secrets as `SSH_PRIVATE_KEY`

But this is **NOT NECESSARY** - your current key should work with the updated workflow! 🚀
