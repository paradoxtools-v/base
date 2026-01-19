#!/bin/bash

# ==========================================
# Felix Pro Premium Installer v2.2
# Version : 2.2.0
# Author  : Mr. Felix Hasgawa
# Telegram: @GlobalBotzXD
# ==========================================

# Colors and Styles
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Animation characters
SPINNER=("⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽" "⣾")

# Configuration
REPO_URL="https://github.com/paradoxtools-v/base/raw/main/Felixv1.5.3.zip"
LOG_FILE="/tmp/felix-install-$(date +%Y%m%d-%H%M%S).log"
VERSION="2.2.0"
INSTALL_DIR="/var/www/pterodactyl"

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║  ███████╗███████╗██╗     ██╗██╗  ██╗    ██████╗ ██████╗  ║"
    echo "║  ██╔════╝██╔════╝██║     ██║╚██╗██╔╝   ██╔════╝██╔═══██╗ ║"
    echo "║  █████╗  █████╗  ██║     ██║ ╚███╔╝    ██║     ██║   ██║ ║"
    echo "║  ██╔══╝  ██╔══╝  ██║     ██║ ██╔██╗    ██║     ██║   ██║ ║"
    echo "║  ██║     ███████╗███████╗██║██╔╝ ██╗   ╚██████╗╚██████╔╝ ║"
    echo "║  ╚═╝     ╚══════╝╚══════╝╚═╝╚═╝  ╚═╝    ╚═════╝ ╚═════╝  ║"
    echo "║                                                          ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    echo "║                PREMIUM INSTALLER v2.2.0                  ║"
    echo "║             Created by: Mr. Felix Hasgawa                ║"
    echo "║                Telegram: @GlobalBotzXD                   ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Spinner animation
spinner() {
    local pid=$1
    local delay=0.1
    local i=0
    while kill -0 $pid 2>/dev/null; do
        printf "\r${SPINNER[$i]} ${BLUE}Processing...${NC}  "
        i=$(( (i+1) % ${#SPINNER[@]} ))
        sleep $delay
    done
    printf "\r${GREEN}✓${NC} ${WHITE}Completed!${NC}          \n"
}

# Logger
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case $level in
        "INFO") echo -e "${BLUE}[INFO]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
    esac
}

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "ERROR" "Script must be run as root"
        echo -e "${RED}✗ This script must be run as root!${NC}"
        echo -e "${YELLOW}Please use: ${WHITE}sudo bash $(basename "$0")${NC}"
        exit 1
    fi
    log_message "SUCCESS" "Root check passed"
}

# Check Pterodactyl directory
check_pterodactyl_dir() {
    log_message "INFO" "Checking Pterodactyl directory..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        log_message "ERROR" "Pterodactyl directory not found: $INSTALL_DIR"
        echo -e "${RED}✗ ERROR: Pterodactyl directory not found!${NC}"
        echo -e "${YELLOW}Directory required: ${WHITE}$INSTALL_DIR${NC}"
        echo -e "${CYAN}Please install Pterodactyl Panel first.${NC}"
        exit 1
    fi
    
    if [ ! -f "$INSTALL_DIR/artisan" ]; then
        log_message "WARNING" "Pterodactyl artisan file not found"
        echo -e "${YELLOW}⚠ Warning: artisan file not found in $INSTALL_DIR${NC}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_message "INFO" "Installation cancelled by user"
            exit 0
        fi
    fi
    
    log_message "SUCCESS" "Pterodactyl directory verified: $INSTALL_DIR"
}

# Check system
check_system() {
    log_message "INFO" "Checking system requirements..."
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        log_message "INFO" "Detected OS: $OS $VER"
        echo -e "${GREEN}✓${NC} ${WHITE}OS:${NC} $OS $VER"
    else
        log_message "WARNING" "Cannot detect OS"
        echo -e "${YELLOW}⚠${NC} ${WHITE}OS:${NC} Unknown"
    fi
    
    # Check memory (handle errors gracefully)
    MEM=$(free -m 2>/dev/null | awk '/^Mem:/{print $2}' || echo "0")
    if [ "$MEM" -lt 1024 ] 2>/dev/null; then
        log_message "WARNING" "Low memory detected: ${MEM}MB"
        echo -e "${YELLOW}⚠${NC} ${WHITE}RAM:${NC} ${MEM}MB ${YELLOW}(Low memory)${NC}"
    else
        log_message "INFO" "Memory: ${MEM}MB"
        echo -e "${GREEN}✓${NC} ${WHITE}RAM:${NC} ${MEM}MB"
    fi
    
    # Check disk space
    DISK=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}' || echo "Unknown")
    log_message "INFO" "Available disk space: $DISK"
    echo -e "${GREEN}✓${NC} ${WHITE}Disk Space:${NC} $DISK available"
}

# Install dependencies
install_dependencies() {
    log_message "INFO" "Installing system dependencies..."
    echo -e "${BLUE}→${NC} ${WHITE}Updating package list...${NC}"
    
    apt-get update > /dev/null 2>&1 &
    spinner $!
    
    echo -e "${BLUE}→${NC} ${WHITE}Installing required packages...${NC}"
    apt-get install -y \
        curl \
        wget \
        git \
        unzip \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https \
        build-essential > /dev/null 2>&1 &
    spinner $!
    
    log_message "SUCCESS" "Dependencies installed"
}

# Install Node.js
install_nodejs() {
    log_message "INFO" "Checking Node.js installation..."
    
    # Check if Node.js is already installed with correct version
    if command -v node > /dev/null; then
        NODE_VERSION=$(node -v 2>/dev/null | cut -d'v' -f2 | cut -d'.' -f1)
        if [[ "$NODE_VERSION" == "20" ]] || [[ "$NODE_VERSION" == "22" ]]; then
            log_message "INFO" "Node.js v$NODE_VERSION already installed"
            echo -e "${GREEN}✓${NC} ${WHITE}Node.js:${NC} v$(node -v) ${GREEN}(Already installed)${NC}"
            return 0
        fi
        echo -e "${YELLOW}⚠${NC} ${WHITE}Removing old Node.js v$NODE_VERSION...${NC}"
        apt-get remove -y nodejs npm > /dev/null 2>&1 &
        spinner $!
    fi
    
    # Install Node.js 20.x
    echo -e "${BLUE}→${NC} ${WHITE}Installing Node.js 20.x...${NC}"
    
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1 &
    spinner $!
    
    apt-get install -y nodejs > /dev/null 2>&1 &
    spinner $!
    
    log_message "SUCCESS" "Node.js installed"
    echo -e "${GREEN}✓${NC} ${WHITE}Node.js:${NC} $(node -v 2>/dev/null) ${GREEN}(Installed)${NC}"
}

# Install Yarn
install_yarn() {
    log_message "INFO" "Checking Yarn installation..."
    
    if ! command -v yarn > /dev/null; then
        echo -e "${BLUE}→${NC} ${WHITE}Installing Yarn...${NC}"
        npm install -g yarn > /dev/null 2>&1 &
        spinner $!
        YARN_VERSION=$(yarn -v 2>/dev/null || echo "unknown")
        log_message "SUCCESS" "Yarn $YARN_VERSION installed"
        echo -e "${GREEN}✓${NC} ${WHITE}Yarn:${NC} $YARN_VERSION ${GREEN}(Installed)${NC}"
    else
        YARN_VERSION=$(yarn -v 2>/dev/null || echo "unknown")
        log_message "INFO" "Yarn already installed"
        echo -e "${GREEN}✓${NC} ${WHITE}Yarn:${NC} $YARN_VERSION ${GREEN}(Already installed)${NC}"
    fi
}

# Download resources
download_resources() {
    log_message "INFO" "Downloading installation resources..."
    echo -e "${BLUE}→${NC} ${WHITE}Downloading Felix Pro resources...${NC}"
    
    cd /tmp || {
        log_message "ERROR" "Cannot cd to /tmp"
        echo -e "${RED}✗ Cannot access /tmp directory${NC}"
        exit 1
    }
    
    if command -v wget > /dev/null; then
        wget -q --show-progress -O FelixPro.zip "$REPO_URL" &
        spinner $!
    elif command -v curl > /dev/null; then
        curl -L -o FelixPro.zip "$REPO_URL" &
        spinner $!
    else
        log_message "ERROR" "No download tool available"
        echo -e "${RED}✗ No download tool found!${NC}"
        exit 1
    fi
    
    if [ ! -f "FelixPro.zip" ]; then
        log_message "ERROR" "Failed to download resources"
        echo -e "${RED}✗ Download failed!${NC}"
        exit 1
    fi
    
    log_message "SUCCESS" "Resources downloaded"
    echo -e "${GREEN}✓${NC} ${WHITE}Download:${NC} Completed"
}

# Extract files
extract_files() {
    log_message "INFO" "Extracting files to $INSTALL_DIR..."
    echo -e "${BLUE}→${NC} ${WHITE}Extracting files to $INSTALL_DIR...${NC}"
    
    # Check if zip file exists
    if [ ! -f "/tmp/FelixPro.zip" ]; then
        log_message "ERROR" "Zip file not found"
        echo -e "${RED}✗ Zip file not found!${NC}"
        exit 1
    fi
    
    # Extract to Pterodactyl directory
    unzip -q -o /tmp/FelixPro.zip -d "$INSTALL_DIR" 2>/dev/null &
    spinner $!
    
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to extract files"
        echo -e "${RED}✗ Extraction failed!${NC}"
        exit 1
    fi
    
    log_message "SUCCESS" "Files extracted"
    echo -e "${GREEN}✓${NC} ${WHITE}Extraction:${NC} Completed"
}

# Set permissions

# Run artisan commands
run_artisan() {
    log_message "INFO" "Running Laravel artisan commands..."
    echo -e "${BLUE}→${NC} ${WHITE}Running Laravel commands...${NC}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        log_message "ERROR" "Install directory not found"
        echo -e "${RED}✗ Install directory not found!${NC}"
        return 1
    fi
    
    cd "$INSTALL_DIR" || {
        log_message "ERROR" "Cannot cd to $INSTALL_DIR"
        echo -e "${RED}✗ Cannot access $INSTALL_DIR${NC}"
        return 1
    }
    
    # Check if artisan exists
    if [ ! -f "artisan" ]; then
        log_message "WARNING" "Artisan file not found, skipping artisan commands"
        echo -e "${YELLOW}⚠ Artisan file not found, skipping...${NC}"
        return 0
    fi
    
    local commands=(
        "migrate --force"
        "view:clear"
        "config:clear"
        "cache:clear"
        "route:clear"
        "optimize"
    )
    
    for cmd in "${commands[@]}"; do
        echo -e "  ${BLUE}›${NC} Running: php artisan $cmd"
        php artisan $cmd > /dev/null 2>&1 &
        spinner $!
        log_message "INFO" "Artisan command: $cmd"
    done
    
    log_message "SUCCESS" "Artisan commands completed"
    echo -e "${GREEN}✓${NC} ${WHITE}Artisan Commands:${NC} Completed"
}

# Build assets
build_assets() {
    log_message "INFO" "Building frontend assets..."
    echo -e "${BLUE}→${NC} ${WHITE}Building frontend assets...${NC}"
    
    if [ ! -d "$INSTALL_DIR" ]; then
        log_message "ERROR" "Install directory not found"
        echo -e "${RED}✗ Install directory not found!${NC}"
        return 1
    fi
    
    cd "$INSTALL_DIR" || {
        log_message "ERROR" "Cannot cd to $INSTALL_DIR"
        echo -e "${RED}✗ Cannot access $INSTALL_DIR${NC}"
        return 1
    }
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        log_message "WARNING" "package.json not found, skipping build"
        echo -e "${YELLOW}⚠ package.json not found, skipping build...${NC}"
        return 0
    fi
    
    echo -e "  ${BLUE}›${NC} Running: yarn install"
    yarn install --frozen-lockfile --production > /dev/null 2>&1 &
    spinner $!
    
    echo -e "  ${BLUE}›${NC} Running: yarn build"
    yarn build:production > /dev/null 2>&1 &
    spinner $!
    
    log_message "SUCCESS" "Assets built"
    echo -e "${GREEN}✓${NC} ${WHITE}Build Assets:${NC} Completed"
}

# Cleanup
cleanup() {
    log_message "INFO" "Cleaning up temporary files..."
    echo -e "${BLUE}→${NC} ${WHITE}Cleaning up...${NC}"
    
    rm -f /tmp/FelixPro.zip 2>/dev/null
    
    # Clear npm/yarn cache silently
    npm cache clean --force > /dev/null 2>&1 || true
    yarn cache clean > /dev/null 2>&1 || true
    
    log_message "SUCCESS" "Cleanup completed"
    echo -e "${GREEN}✓${NC} ${WHITE}Cleanup:${NC} Completed"
}

# Show summary
show_summary() {
    local node_version=$(node -v 2>/dev/null || echo "Not installed")
    local yarn_version=$(yarn -v 2>/dev/null || echo "Not installed")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║               FELIX PRO INSTALLATION SUMMARY             ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  ${WHITE}•${NC} ${GREEN}Installation Time${NC}  : ${WHITE}$timestamp${NC}"
    echo -e "${GREEN}║${NC}  ${WHITE}•${NC} ${GREEN}Node.js Version${NC}    : ${WHITE}$node_version${NC}"
    echo -e "${GREEN}║${NC}  ${WHITE}•${NC} ${GREEN}Yarn Version${NC}       : ${WHITE}$yarn_version${NC}"
    echo -e "${GREEN}║${NC}  ${WHITE}•${NC} ${GREEN}Install Directory${NC}  : ${WHITE}$INSTALL_DIR${NC}"
    echo -e "${GREEN}║${NC}  ${WHITE}•${NC} ${GREEN}Felix Install${NC}           : ${WHITE}V1.2.0${NC}"
    echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║${NC}            ${WHITE}🎉 Installation Successful! 🎉${NC}                ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}       ${CYAN}Felix Pro has been installed successfully${NC}       ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}                                                          ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}          ${YELLOW}Need help? Telegram: @GlobalBotzXD${NC}          ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    
    log_message "SUCCESS" "=== Installation completed successfully ==="
}

# Installation confirmation
confirm_installation() {
    echo -e "\n${YELLOW}══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}               INSTALLATION CONFIRMATION               ${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Target Directory:${NC} ${CYAN}$INSTALL_DIR${NC}"
    echo -e "${WHITE}Log File:${NC} ${CYAN}$LOG_FILE${NC}"
    echo -e "${WHITE}Version:${NC} ${CYAN}$VERSION${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════════${NC}"
    
    read -p "Do you want to proceed with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_message "INFO" "Installation cancelled by user"
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi
    
    log_message "INFO" "User confirmed installation"
}

# Main installation process
main() {
    # Start logging
    log_message "INFO" "=== Felix Pro Premium Installation Started ==="
    log_message "INFO" "Version: $VERSION"
    log_message "INFO" "Timestamp: $(date)"
    
    # Show banner
    show_banner
    
    # Check requirements
    check_root
    check_pterodactyl_dir
    check_system
    
    # Confirm installation
    confirm_installation
    
    echo -e "\n${WHITE}Starting installation process...${NC}"
    sleep 2
    
    # Installation steps
    local steps=(
        "install_dependencies:1. Installing system dependencies"
        "install_nodejs:2. Installing Node.js"
        "install_yarn:3. Installing Yarn"
        "download_resources:4. Downloading resources"
        "extract_files:5. Extracting files"
        "run_artisan:6. Running Laravel commands"
        "build_assets:7. Building assets"
        "cleanup:8. Cleaning up"
    )
    
    # Execute all steps
    for step in "${steps[@]}"; do
        IFS=':' read -r function description <<< "$step"
        
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}$description${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        if ! $function; then
            log_message "ERROR" "Step failed: $description"
            echo -e "${RED}✗ Step failed: $description${NC}"
            echo -e "${YELLOW}Continuing with next step...${NC}"
        fi
    done
    
    # Show summary
    show_summary
    
    # Exit
    exit 0
}

# Error handler
error_handler() {
    local exit_code=$?
    local line_no=$1
    
    log_message "ERROR" "Error at line $line_no (exit code: $exit_code)"
    
    echo -e "\n${RED}══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}                    INSTALLATION FAILED                    ${NC}"
    echo -e "${RED}══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Error occurred at line: $line_no${NC}"
    echo -e "${YELLOW}Exit code: $exit_code${NC}"
    echo -e "${YELLOW}Check log file: $LOG_FILE${NC}"
    echo -e "${RED}══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}Need help? Contact: @GlobalBotzXD on Telegram${NC}"
    
    # Cleanup on error
    rm -f /tmp/FelixPro.zip 2>/dev/null
    
    exit $exit_code
}

# Set trap for errors
trap 'error_handler ${LINENO}' ERR

# Run main function
main
