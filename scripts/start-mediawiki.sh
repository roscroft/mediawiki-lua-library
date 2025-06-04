#!/bin/bash
# Start MediaWiki Container and Open Browser
# This script initializes a MediaWiki Docker container and opens VS Code Simple Browser

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting MediaWiki Container and Browser Interface${NC}"

# Docker configuration
DOCKER_IMAGE="mediawiki-lua-test"
DOCKER_CONTAINER="mediawiki-dev"
DOCKER_PORT="8080"

# Function to check if Docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed or not in PATH${NC}"
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}Docker daemon is not running${NC}"
        return 1
    fi
    
    return 0
}

# Function to build Docker image if needed
build_docker_image() {
    echo -e "${BLUE}Checking Docker image...${NC}"
    
    if ! docker image inspect $DOCKER_IMAGE &> /dev/null; then
        echo -e "${BLUE}Building Docker image: $DOCKER_IMAGE${NC}"
        if docker build -t $DOCKER_IMAGE .; then
            echo -e "${GREEN}✓ Docker image built successfully${NC}"
        else
            echo -e "${RED}✗ Failed to build Docker image${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✓ Docker image $DOCKER_IMAGE already exists${NC}"
    fi
}

# Function to start Docker container
start_docker_container() {
    echo -e "${BLUE}Starting MediaWiki Docker container...${NC}"
    
    # Stop and remove existing container if it exists
    if docker ps -a | grep -q $DOCKER_CONTAINER; then
        echo "Stopping existing container..."
        docker stop $DOCKER_CONTAINER &> /dev/null || true
        docker rm $DOCKER_CONTAINER &> /dev/null || true
    fi
    
    # Start new container with volume mounts
    if docker run -d \
        --name $DOCKER_CONTAINER \
        -p $DOCKER_PORT:80 \
        -v "$(pwd)/src:/var/www/html/src" \
        -v "$(pwd)/tests:/var/www/html/tests" \
        -v "$(pwd)/build:/var/www/html/build" \
        $DOCKER_IMAGE; then
        
        echo -e "${GREEN}✓ Docker container started: $DOCKER_CONTAINER${NC}"
        
        # Wait for container to be ready
        echo "Waiting for MediaWiki to initialize..."
        sleep 10
        
        # Test if container is responding
        local retries=0
        while [ $retries -lt 30 ]; do
            if docker exec $DOCKER_CONTAINER php -r "echo 'Container ready';" &> /dev/null; then
                echo -e "${GREEN}✓ Container is ready${NC}"
                return 0
            fi
            sleep 2
            retries=$((retries + 1))
        done
        
        echo -e "${RED}✗ Container failed to become ready${NC}"
        return 1
    else
        echo -e "${RED}✗ Failed to start Docker container${NC}"
        return 1
    fi
}

# Main execution
if ! check_docker; then
    echo -e "${RED}❌ Docker is not available. Please install Docker and try again.${NC}"
    exit 1
fi

if ! build_docker_image; then
    echo -e "${RED}❌ Failed to build Docker image.${NC}"
    exit 1
fi

if ! start_docker_container; then
    echo -e "${RED}❌ Failed to start Docker container.${NC}"
    exit 1
fi

# Test if MediaWiki is responding
echo -e "${BLUE}Testing MediaWiki availability...${NC}"
sleep 5

if curl -s -f http://localhost:$DOCKER_PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✓ MediaWiki is responding at http://localhost:$DOCKER_PORT${NC}"
    
    # MediaWiki is ready, provide access information
    echo -e "\n${GREEN}🎉 MediaWiki container is now running and accessible!${NC}"
    echo -e "${BLUE}Container: $DOCKER_CONTAINER${NC}"
    echo -e "${BLUE}URL: http://localhost:$DOCKER_PORT${NC}"
    echo -e "${BLUE}To stop: docker stop $DOCKER_CONTAINER${NC}"
    echo -e "${BLUE}To remove: docker rm $DOCKER_CONTAINER${NC}"
    
    echo -e "\n${YELLOW}💡 To open MediaWiki in VS Code Simple Browser:${NC}"
    echo -e "${BLUE}  1. Press Ctrl+Shift+P (Command Palette)${NC}"
    echo -e "${BLUE}  2. Type 'Simple Browser: Show'${NC}"
    echo -e "${BLUE}  3. Enter URL: http://localhost:$DOCKER_PORT${NC}"
    echo -e "${YELLOW}  Or use the 'Open MediaWiki in Simple Browser' VS Code task${NC}"
    
else
    echo -e "${YELLOW}⚠ MediaWiki not yet responding. Container may need more time to initialize.${NC}"
    echo -e "${BLUE}Please wait a moment and navigate to: http://localhost:$DOCKER_PORT${NC}"
fi
