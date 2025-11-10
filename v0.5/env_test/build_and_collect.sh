#!/bin/bash
################################################################################
# Build and Collect Executable Script
# 
# Purpose: Builds debug executable and collects it for Docker deployment
# Usage: ./build_and_collect.sh [--release] [--clean]
# 
# NOTE: Run this on your LOCAL MACHINE (with Rust toolchain installed)
#       NOT on the Synology NAS
#
# For Synology DS1821+ (AMD Ryzen, x86_64), this builds with the correct target
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Target architecture for Synology DS1821+
# DS1821+ uses AMD Ryzen V1500B (x86_64)
TARGET_ARCH="x86_64-unknown-linux-gnu"
BUILD_TYPE="debug"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./build_and_collect.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --release    Build optimized release version"
            echo "  --clean      Clean build artifacts before building"
            echo "  --help       Show this help message"
            echo ""
            echo "Target: Synology DS1821+ (x86_64-unknown-linux-gnu)"
            exit 0
            ;;
    esac
done

echo -e "${YELLOW}=== Building for Synology DS1821+ ===${NC}"
echo "Target: $TARGET_ARCH"
echo "Build type: $BUILD_TYPE"
echo ""

# Navigate to project root (two levels up from src/env_test)
cd "$(dirname "$0")/../.."
PROJECT_ROOT=$(pwd)

echo "Project root: $PROJECT_ROOT"

# Verify Rust toolchain
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}ERROR: cargo not found. Install Rust toolchain first.${NC}"
    exit 1
fi

# Check if target is installed
if ! rustup target list | grep -q "$TARGET_ARCH (installed)"; then
    echo -e "${YELLOW}Installing target $TARGET_ARCH...${NC}"
    rustup target add $TARGET_ARCH
fi

# Clean previous build artifacts (optional)
if [ "$CLEAN_BUILD" == "true" ]; then
    echo -e "${YELLOW}Cleaning previous build artifacts...${NC}"
    cargo clean
fi

# Build executable for DS1821+
echo -e "${YELLOW}Building with cargo for $TARGET_ARCH...${NC}"
if [ "$BUILD_TYPE" == "release" ]; then
    cargo build --target $TARGET_ARCH --release
    EXECUTABLE_PATH="target/$TARGET_ARCH/release/set_backend"
else
    cargo build --target $TARGET_ARCH
    EXECUTABLE_PATH="target/$TARGET_ARCH/debug/set_backend"
fi

# Check if build succeeded
if [ ! -f "$EXECUTABLE_PATH" ]; then
    echo -e "${RED}ERROR: Build failed - executable not found at $EXECUTABLE_PATH${NC}"
    exit 1
fi

# Get executable info
EXECUTABLE_SIZE=$(du -h "$EXECUTABLE_PATH" | cut -f1)
echo -e "${GREEN}✓ Build successful${NC}"
echo "  Build type: $BUILD_TYPE"
echo "  Target: $TARGET_ARCH"
echo "  Executable size: $EXECUTABLE_SIZE"
echo "  Path: $EXECUTABLE_PATH"

# Verify it's the correct architecture (optional - requires 'file' command)
if command -v file &> /dev/null; then
    FILE_INFO=$(file "$EXECUTABLE_PATH")
    if echo "$FILE_INFO" | grep -q "x86-64"; then
        echo -e "${GREEN}✓ Verified: x86_64 architecture (compatible with DS1821+)${NC}"
    else
        echo -e "${RED}WARNING: Unexpected architecture:${NC}"
        echo "  $FILE_INFO"
        echo -e "${YELLOW}This may not work on Synology DS1821+${NC}"
    fi
else
    echo -e "${YELLOW}Note: 'file' command not available, skipping architecture verification${NC}"
fi

# Copy executable to Docker context
DOCKER_CONTEXT="$PROJECT_ROOT/src/env_test"
echo -e "${YELLOW}Copying executable to Docker context...${NC}"
cp "$EXECUTABLE_PATH" "$DOCKER_CONTEXT/set_backend"

# Verify copy
if [ -f "$DOCKER_CONTEXT/set_backend" ]; then
    echo -e "${GREEN}✓ Executable copied to $DOCKER_CONTEXT${NC}"
    ls -lh "$DOCKER_CONTEXT/set_backend"
else
    echo -e "${RED}ERROR: Failed to copy executable${NC}"
    exit 1
fi

echo -e "${GREEN}=== Ready for deployment ===${NC}"
echo ""
echo "Deployment options:"
echo ""
echo "A. Deploy to Synology NAS:"
echo "   1. Transfer files:"
echo "      ./transfer_to_nas.sh <nas_ip> <username>"
echo "   2. SSH to NAS and run:"
echo "      cd /volume1/docker/settest/backend"
echo "      ./deploy_nas.sh --detached"
echo ""
echo "B. Test locally (if x86_64 Linux):"
echo "   cd src/env_test"
echo "   docker-compose up --build"
echo ""
echo "Build info:"
echo "  Target: $TARGET_ARCH (Synology DS1821+ compatible)"
echo "  Type: $BUILD_TYPE"
echo "  Size: $EXECUTABLE_SIZE"
