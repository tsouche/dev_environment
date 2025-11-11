# SSH Key Management Improvements - Proposal

## Current Issues

1. **Hardcoded authorized_keys in base image**: The base Docker image (`Dockerfile.rustdev`) has a specific user's public key baked in at build time
2. **No SSH connectivity testing**: The deployment script doesn't verify that SSH actually works
3. **Not portable**: Each user/machine would need to rebuild the base image with their own key
4. **Key mismatch**: The deploy script generates/copies keys AFTER the image is built, creating a disconnect

## Proposed Solution

### Option 1: Runtime Key Injection (Recommended)

**Advantages:**
- Base image remains generic and portable
- Each user gets their own SSH keys automatically
- No image rebuild needed
- Easy to test and validate

**Implementation:**

1. **Modify `env_dev/Dockerfile`** to copy authorized_keys at env-specific build time:
```dockerfile
FROM tsouche/rust_dev_container:v0.5.0

# Copy user-specific SSH public key
USER root
COPY authorized_keys /home/rustdev/.ssh/authorized_keys
RUN chown 1026:110 /home/rustdev/.ssh/authorized_keys && \
    chmod 600 /home/rustdev/.ssh/authorized_keys

WORKDIR /workspace
USER root

CMD ["/usr/sbin/sshd", "-D"]
```

2. **Remove authorized_keys from base image** (`build_image_dev/Dockerfile.rustdev`):
   - Create a dummy/placeholder authorized_keys file in base image
   - Let environment-specific builds override it

3. **Enhance deploy-dev.ps1**:
   - Check for SSH keys (already done)
   - Generate if missing (already done)
   - Copy to authorized_keys (already done)
   - **ADD: Test SSH connectivity after container starts**
   - **ADD: Provide troubleshooting info if SSH fails**

### Option 2: Volume Mount (Alternative)

Mount the authorized_keys file as a volume in docker-compose:

```yaml
volumes:
  - ${PROJECT_PATH}:/workspace
  - ./authorized_keys:/home/rustdev/.ssh/authorized_keys:ro
```

**Pros**: Dynamic updates without rebuild
**Cons**: File permission issues on Windows, requires container restart

## Recommended Implementation Steps

1. ✅ Keep current key generation logic in `deploy-dev.ps1`
2. ✅ Ensure `env_dev/Dockerfile` copies the local authorized_keys
3. ⚠️ Update base image to use a placeholder authorized_keys
4. ➕ **ADD: SSH connectivity test function**
5. ➕ **ADD: Key fingerprint display for verification**
6. ➕ **ADD: Retry logic for SSH connection**

## New Functions to Add

### Test-SSHConnection
```powershell
function Test-SSHConnection {
    param(
        [string]$Host = "localhost",
        [int]$Port = 2222,
        [string]$User = "rustdev",
        [string]$IdentityFile,
        [int]$MaxRetries = 5
    )
    
    Write-Host "Testing SSH connectivity..." -ForegroundColor Yellow
    
    for ($i = 1; $i -le $MaxRetries; $i++) {
        Write-Host "  Attempt $i of $MaxRetries..." -ForegroundColor Gray
        
        $result = & ssh -o StrictHostKeyChecking=no `
                       -o UserKnownHostsFile=/dev/null `
                       -o ConnectTimeout=5 `
                       -i $IdentityFile `
                       -p $Port `
                       "$User@$Host" `
                       "echo 'SSH_OK'" 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $result -match "SSH_OK") {
            Write-Success "SSH connection successful!"
            return $true
        }
        
        Start-Sleep -Seconds 2
    }
    
    Write-Host "[ERROR] SSH connection failed after $MaxRetries attempts" -ForegroundColor Red
    return $false
}
```

### Show-SSHKeyFingerprint
```powershell
function Show-SSHKeyFingerprint {
    param([string]$PublicKeyPath)
    
    if (Test-Path $PublicKeyPath) {
        Write-Host "SSH Key Fingerprint:" -ForegroundColor Cyan
        & ssh-keygen -lf $PublicKeyPath
    }
}
```

## Testing Checklist

- [ ] Fresh Windows machine (no SSH keys)
- [ ] Existing SSH keys (ed25519)
- [ ] Existing SSH keys (RSA)
- [ ] SSH connectivity test passes
- [ ] VS Code Remote-SSH connection works
- [ ] Key regeneration scenario
- [ ] Multiple deployments/rebuilds

## Migration Path

1. **Phase 1** (Current v0.5):
   - Keep current setup working
   - Add SSH connectivity tests
   - Add better error messages

2. **Phase 2** (Future v0.6):
   - Rebuild base image without specific authorized_keys
   - Use placeholder in base image
   - All environments inject their own keys

3. **Phase 3** (Optional):
   - Add support for multiple SSH keys
   - Add SSH key rotation support
