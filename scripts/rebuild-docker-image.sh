#!/bin/bash
# Rebuild the Docker image used by the test pipeline

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOCKER_IMAGE="mediawiki-lua-test"

echo -e "${BLUE}=== Rebuilding Docker Image: ${DOCKER_IMAGE} ===${NC}"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker daemon is not running${NC}"
    exit 1
fi

# Remove existing containers using this image
echo -e "${YELLOW}Checking for containers using ${DOCKER_IMAGE}...${NC}"
CONTAINERS=$(docker ps -a -q --filter ancestor=${DOCKER_IMAGE} 2>/dev/null)
if [ -n "$CONTAINERS" ]; then
    echo -e "${YELLOW}Found containers using this image. Stopping and removing them...${NC}"
    docker stop $CONTAINERS 2>/dev/null || true
    docker rm $CONTAINERS 2>/dev/null || true
    echo -e "${GREEN}✓ Containers removed${NC}"
else
    echo -e "${GREEN}✓ No containers found using this image${NC}"
fi

# Remove existing image
echo -e "${YELLOW}Removing existing image ${DOCKER_IMAGE} if it exists...${NC}"
if docker image inspect $DOCKER_IMAGE &> /dev/null; then
    docker rmi -f $DOCKER_IMAGE
    echo -e "${GREEN}✓ Image removed successfully${NC}"
else
    echo -e "${GREEN}✓ No existing image found${NC}"
fi

# Build new image
echo -e "${YELLOW}Building new Docker image...${NC}"
if docker build -t $DOCKER_IMAGE -f docker/Dockerfile .; then
    echo -e "${GREEN}✓ Docker image built successfully${NC}"
    echo -e "${BLUE}Image details:${NC}"
    docker image ls $DOCKER_IMAGE
else
    echo -e "${RED}✗ Failed to build Docker image${NC}"
    exit 1
fi

echo -e "\n${GREEN}Docker image '${DOCKER_IMAGE}' has been successfully rebuilt.${NC}"
echo -e "${BLUE}You can now run the test pipeline with the new image.${NC}"
