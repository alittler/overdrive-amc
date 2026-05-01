#!/bin/bash

# 1. Colors for feedback
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Overdrive-AMC installation...${NC}"

# 2. Check for dependencies (e.g., git, python, or docker)
if ! command -v git &> /dev/null; then
    echo "git is not installed. Installing..."
    sudo apt-get update && sudo apt-get install -y git
fi

# 3. Create installation directory
INSTALL_DIR="$HOME/.overdrive-amc"
mkdir -p "$INSTALL_DIR"

# 4. Clone or update the repository
if [ -d "$INSTALL_DIR/.git" ]; then
    echo "Updating existing installation..."
    cd "$INSTALL_DIR" && git pull
else
    git clone https://github.com/alittler/overdrive-amc.git "$INSTALL_DIR"
fi

# 5. Run your specific setup logic (e.g., pip install, chmod +x)
cd "$INSTALL_DIR"
# Example: chmod +x your-script.py

echo -e "${GREEN}Installation complete!${NC}"
