#!/bin/bash
################################################################################
# Setup SSH Passwordless Access to Synology NAS
# Usage: ./setup_ssh_access.sh [NAS_IP] [NAS_USER] [NAS_PORT]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
NAS_IP="${1:-100.100.10.1}"
NAS_USER="${2:-thierry}"
NAS_PORT="${3:-5522}"
SSH_KEY_TYPE="${4:-ed25519}"  # ed25519 or rsa

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  SSH Passwordless Access Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Target: ${NAS_USER}@${NAS_IP}:${NAS_PORT}"
echo "Key type: ${SSH_KEY_TYPE}"
echo ""

################################################################################
# Step 1: Check if SSH key exists
################################################################################
SSH_KEY_FILE=""
SSH_PUB_FILE=""

if [ "${SSH_KEY_TYPE}" = "ed25519" ]; then
    SSH_KEY_FILE="$HOME/.ssh/id_ed25519"
    SSH_PUB_FILE="$HOME/.ssh/id_ed25519.pub"
else
    SSH_KEY_FILE="$HOME/.ssh/id_rsa"
    SSH_PUB_FILE="$HOME/.ssh/id_rsa.pub"
fi

echo -e "${YELLOW}[1/5] Checking SSH key...${NC}"

if [ -f "${SSH_KEY_FILE}" ]; then
    echo -e "${GREEN}✓ SSH key found: ${SSH_KEY_FILE}${NC}"
else
    echo -e "${YELLOW}No SSH key found. Generating new key...${NC}"
    
    if [ "${SSH_KEY_TYPE}" = "ed25519" ]; then
        ssh-keygen -t ed25519 -f "${SSH_KEY_FILE}" -N "" -C "$(whoami)@$(hostname)"
    else
        ssh-keygen -t rsa -b 4096 -f "${SSH_KEY_FILE}" -N "" -C "$(whoami)@$(hostname)"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${ SSH key generated: ${SSH_KEY_FILE}${NC}"GREEN}
    else
        echo -e "${RED}ERROR: Failed to generate SSH key${NC}"
        exit 1
    fi
fi
echo ""

################################################################################
# Step 2: Test SSH connectivity (with password)
################################################################################
echo -e "${YELLOW}[2/5] Testing SSH connectivity...${NC}"
echo "You will be prompted for the NAS password to test connectivity."
echo ""

if ssh -p ${NAS_PORT} -o BatchMode=no -o ConnectTimeout=5 ${NAS_USER}@${NAS_IP} "echo 'Connection OK'" 2>/dev/null; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
else
    echo -e "${RED}ERROR: Cannot connect to NAS${NC}"
    echo "Please check:"
    echo "  - Tailscale is running and connected"
    echo "  - NAS IP is correct: ${NAS_IP}"
    echo "  - SSH port is correct: ${NAS_PORT}"
    echo "  - User exists on NAS: ${NAS_USER}"
    exit 1
fi
echo ""

################################################################################
# Step 3: Copy public key to NAS
################################################################################
echo -e "${YELLOW}[3/5] Copying public key to NAS...${NC}"
echo "You will be prompted for the NAS password one last time."
echo ""

# Check if ssh-copy-id is available
if command -v ssh-copy-id >/dev/null 2>&1; then
    # Use ssh-copy-id (recommended)
    ssh-copy-id -i "${SSH_PUB_FILE}" -p ${NAS_PORT} ${NAS_USER}@${NAS_IP}
else
    # Manual method (for systems without ssh-copy-id, like some Windows environments)
    cat "${SSH_PUB_FILE}" | ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_IP} \
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo 'Key added successfully'"
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Public key copied to NAS${NC}"
else
    echo -e "${RED}ERROR: Failed to copy public key${NC}"
    exit 1
fi
echo ""

################################################################################
# Step 4: Test passwordless access
################################################################################
echo -e "${YELLOW}[4/5] Testing passwordless access...${NC}"

if ssh -p ${NAS_PORT} -o BatchMode=yes -o ConnectTimeout=5 ${NAS_USER}@${NAS_IP} "echo 'Passwordless access OK'" 2>/dev/null; then
    echo -e "${GREEN}✓ Passwordless SSH access works!${NC}"
else
    echo -e "${RED}ERROR: Passwordless access failed${NC}"
    echo "The key was copied but authentication still fails."
    echo "Check NAS SSH configuration:"
    echo "  - PubkeyAuthentication yes"
    echo "  - AuthorizedKeysFile .ssh/authorized_keys"
    exit 1
fi
echo ""

################################################################################
# Step 5: Create/Update SSH config
################################################################################
echo -e "${YELLOW}[5/5] Creating SSH config entry...${NC}"

SSH_CONFIG="$HOME/.ssh/config"
HOST_ENTRY="synology-nas"

# Check if entry already exists
if grep -q "^Host ${HOST_ENTRY}$" "${SSH_CONFIG}" 2>/dev/null; then
    echo -e "${YELLOW}SSH config entry already exists${NC}"
else
    # Create .ssh directory if it doesn't exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Append host entry
    cat >> "${SSH_CONFIG}" << EOFCONFIG

# Synology NAS - Auto-generated by setup_ssh_access.sh
Host ${HOST_ENTRY}
    HostName ${NAS_IP}
    User ${NAS_USER}
    Port ${NAS_PORT}
    IdentityFile ${SSH_KEY_FILE}
    ForwardAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOFCONFIG
    
    chmod 600 "${SSH_CONFIG}"
    echo -e "${GREEN}✓ SSH config entry created${NC}"
fi
echo ""

################################################################################
# Summary
################################################################################
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "You can now connect to the NAS without password:"
echo ""
echo -e "  ${BLUE}ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_IP}${NC}"
echo ""
echo "Or simply:"
echo ""
echo -e "  ${BLUE}ssh ${HOST_ENTRY}${NC}"
echo ""
echo "Deployment scripts will now work without password prompts:"
echo ""
echo -e "  ${BLUE}./transfer_to_nas.sh${NC}"
echo -e "  ${BLUE}./full_deploy.sh ${NAS_IP}${NC}"
echo ""

