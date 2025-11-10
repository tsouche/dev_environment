#!/bin/bash
################################################################################
# Build and Push Test/Prod Base Image on NAS via SSH
# Usage: ./build_and_push_on_nas.sh [VERSION]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
NAS_HOST="100.100.10.1"
NAS_PORT="5522"
NAS_USER="thierry"
DOCKERHUB_USER="tsouche"
IMAGE_NAME="set_backend_testprod"
DOCKERFILE="Dockerfile.testprod"

# Get version from argument or detect from Cargo.toml
if [ -n "$1" ]; then
    VERSION="$1"
elif [ -f "../../Cargo.toml" ]; then
    VERSION=$(grep '^version' ../../Cargo.toml | head -1 | sed 's/.*"\(.*\)".*/\1/')
    echo -e "${BLUE}Detected version from Cargo.toml: ${VERSION}${NC}"
    echo ""
else
    echo -e "${RED}ERROR: Cannot determine version${NC}"
    echo "Usage: ./build_and_push_on_nas.sh [VERSION]"
    exit 1
fi

# Validate version format (e.g., 0.6.0)
if ! echo "${VERSION}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo -e "${RED}ERROR: Invalid version format '${VERSION}'${NC}"
    echo "Expected format: X.Y.Z (e.g., 0.6.0)"
    exit 1
fi

FULL_IMAGE="${DOCKERHUB_USER}/${IMAGE_NAME}"
VERSION_TAG="${FULL_IMAGE}:v${VERSION}"
MAJOR_MINOR=$(echo ${VERSION} | cut -d. -f1,2)
MINOR_TAG="${FULL_IMAGE}:v${MAJOR_MINOR}"
LATEST_TAG="${FULL_IMAGE}:latest"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Build Test/Prod Image on NAS${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "NAS: ${NAS_USER}@${NAS_HOST}:${NAS_PORT}"
echo "Image: ${FULL_IMAGE}"
echo "Version: ${VERSION}"
echo "Tags: v${VERSION}, v${MAJOR_MINOR}, latest"
echo ""

# Create temporary directory on NAS
TEMP_DIR="/tmp/docker_build_testprod_$$"

echo -e "${YELLOW}[1/7] Creating temporary directory on NAS...${NC}"
ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "mkdir -p ${TEMP_DIR}"
echo -e "${GREEN}✓ Directory created: ${TEMP_DIR}${NC}"
echo ""

# Transfer Dockerfile
echo -e "${YELLOW}[2/7] Transferring Dockerfile...${NC}"
scp -P ${NAS_PORT} ${DOCKERFILE} ${NAS_USER}@${NAS_HOST}:${TEMP_DIR}/Dockerfile
echo -e "${GREEN}✓ Dockerfile transferred${NC}"
echo ""

# Check DockerHub login on NAS (and login if needed)
echo -e "${YELLOW}[3/7] Checking DockerHub login on NAS...${NC}"
if ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "sudo -n /usr/local/bin/docker info 2>&1 | grep -q 'Username: ${DOCKERHUB_USER}'"; then
    echo -e "${GREEN}✓ Already logged in as ${DOCKERHUB_USER}${NC}"
else
    echo -e "${YELLOW}Not logged in. Logging in to DockerHub...${NC}"
    read -sp "Enter DockerHub password for ${DOCKERHUB_USER}: " DOCKER_PASSWORD
    echo ""
    
    if [ -z "${DOCKER_PASSWORD}" ]; then
        echo -e "${RED}ERROR: Password cannot be empty${NC}"
        exit 1
    fi
    
    ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "echo '${DOCKER_PASSWORD}' | sudo -n /usr/local/bin/docker login -u ${DOCKERHUB_USER} --password-stdin"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully logged in to DockerHub${NC}"
    else
        echo -e "${RED}ERROR: DockerHub login failed${NC}"
        exit 1
    fi
fi
echo ""

# Build image on NAS
echo -e "${YELLOW}[4/7] Building image on NAS...${NC}"
ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} << EOSSH
cd ${TEMP_DIR}
sudo -n /usr/local/bin/docker build \
    -t ${VERSION_TAG} \
    --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
    --build-arg VERSION=${VERSION} \
    -f Dockerfile \
    .
EOSSH

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Build failed${NC}"
    ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "rm -rf ${TEMP_DIR}"
    exit 1
fi
echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# Tag versions
echo -e "${YELLOW}[5/7] Tagging versions...${NC}"
ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} << EOSSH
sudo -n /usr/local/bin/docker tag ${VERSION_TAG} ${MINOR_TAG}
sudo -n /usr/local/bin/docker tag ${VERSION_TAG} ${LATEST_TAG}
EOSSH
echo -e "${GREEN}✓ Tags created${NC}"
echo ""

# Push to DockerHub
echo -e "${YELLOW}[6/7] Pushing to DockerHub...${NC}"
ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} << EOSSH
sudo -n /usr/local/bin/docker push ${VERSION_TAG}
sudo -n /usr/local/bin/docker push ${MINOR_TAG}
sudo -n /usr/local/bin/docker push ${LATEST_TAG}
EOSSH

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Push failed${NC}"
    ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "rm -rf ${TEMP_DIR}"
    exit 1
fi
echo -e "${GREEN}✓ Push successful${NC}"
echo ""

# Cleanup
echo -e "${YELLOW}[7/7] Cleaning up...${NC}"
ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "rm -rf ${TEMP_DIR}"
echo -e "${GREEN}✓ Cleanup complete${NC}"
echo ""

# Summary
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}  Build Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Image published to DockerHub:"
echo "  docker pull ${VERSION_TAG}"
echo "  docker pull ${MINOR_TAG}"
echo "  docker pull ${LATEST_TAG}"
echo ""
echo "Image info on NAS:"
ssh -p ${NAS_PORT} ${NAS_USER}@${NAS_HOST} "sudo -n /usr/local/bin/docker images ${FULL_IMAGE} --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}'"
echo ""
