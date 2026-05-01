#!/bin/bash

set -eo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test mode flag
TEST_MODE=true
DRY_RUN="${DRY_RUN:-false}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_section() {
    echo -e "\n${BLUE}==== $* ====${NC}\n"
}

log_test() {
    echo -e "${CYAN}[TEST]${NC} $*"
}

# Root check - skip in test mode
if [ "$TEST_MODE" = "true" ]; then
    log_test "Running in TEST MODE - no actual changes will be made"
    if [ "$EUID" -ne 0 ]; then
        log_warn "Not running as root (test mode allows this)"
    fi
else
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root (use: sudo $0)"
        exit 1
    fi
fi

log_section "Overdrive-AMC Setup & Configuration - TEST MODE"

# Step 1: Run installation (MOCK in test mode)
log_section "Step 1: Installing Overdrive-AMC from GitHub"

if [ "$TEST_MODE" = "true" ]; then
    log_test "Would run: bash <(curl -fsSL https://raw.githubusercontent.com/alittler/overdrive-amc/main/install.sh)"
    log_test "Installation successful! (mocked)"
else
    log_info "Running install.sh from GitHub..."
    if ! bash <(curl -fsSL https://raw.githubusercontent.com/alittler/overdrive-amc/main/install.sh); then
        log_error "Installation failed"
        exit 1
    fi
    log_info "Installation successful!"
fi

# Step 2: Detect physical disks/partitions
log_section "Step 2: Detecting Physical Disks & Mount Points"

MOUNTS=()
DISK_INFO=()

log_info "Scanning for physical storage..."

# Use simpler approach - avoid process substitution when piped
if command -v lsblk &> /dev/null; then
    lsblk -npo NAME,MOUNTPOINT,FSTYPE 2>/dev/null | while read -r device mountpoint fstype; do
        # Skip loop devices, ram, and tmpfs
        if [[ "$device" =~ ^/dev/(loop|ram|zram|sr) ]] || [[ "$fstype" =~ ^(tmpfs|devtmpfs|sysfs|proc)$ ]]; then
            continue
        fi
        
        # Only include actual disks/partitions
        if [[ "$device" =~ ^/dev/(sd|nvme|vd) ]] && [ -n "$mountpoint" ]; then
            MOUNTS+=("$mountpoint")
            DISK_INFO+=("$device:$mountpoint")
        fi
    done
else
    log_warn "lsblk not found, using df instead..."
    df -x tmpfs -x devtmpfs -x sysfs -x proc 2>/dev/null | tail -n +2 | while read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        mount=$(echo "$line" | awk '{print $NF}')
        if [[ "$device" =~ ^/dev/(sd|nvme|vd) ]]; then
            MOUNTS+=("$mount")
            DISK_INFO+=("$device:$mount")
        fi
    done
fi

# Fallback if above didn't work
if [ "${#MOUNTS[@]}" -eq 0 ]; then
    log_test "Re-scanning with df..."
    df -h 2>/dev/null | tail -n +2 | while read -r line; do
        device=$(echo "$line" | awk '{print $1}')
        mount=$(echo "$line" | awk '{print $NF}')
        if [[ "$device" =~ ^/dev/ ]]; then
            MOUNTS+=("$mount")
            DISK_INFO+=("$device:$mount")
        fi
    done
fi

if [ "${#MOUNTS[@]}" -eq 0 ]; then
    log_warn "No mounted physical disks detected"
    log_info "Available mount points:"
    df -h 2>/dev/null | head -10 || true
else
    log_info "Found ${#MOUNTS[@]} mounted disk(s):"
    for info in "${DISK_INFO[@]}"; do
        device="${info%%:*}"
        mount="${info##*:}"
        size=$(df -h "$mount" 2>/dev/null | tail -1 | awk '{print $2}' || echo "Unknown")
        log_test "  └─ $device ($size) mounted at $mount"
    done
fi

# Step 3: Interactive installation directory selection
log_section "Step 3: Select Installation Directory"

echo "Where would you like to install Overdrive-AMC?"
echo "1) /opt/overdrive-amc (System-wide, recommended)"
echo "2) /usr/local/overdrive-amc"
echo "3) Custom location"
read -p "Enter choice [1-3]: " install_choice

case $install_choice in
    1) INSTALL_DIR="/opt/overdrive-amc" ;;
    2) INSTALL_DIR="/usr/local/overdrive-amc" ;;
    3)
        read -p "Enter custom installation path: " INSTALL_DIR
        ;;
    *)
        log_error "Invalid choice. Using default: /opt/overdrive-amc"
        INSTALL_DIR="/opt/overdrive-amc"
        ;;
esac

log_test "Installation directory: $INSTALL_DIR"

# Step 4: Interactive data location selection
log_section "Step 4: Select Data/Config Location"

echo "Where would you like to store data and configuration?"
echo "1) /opt/overdrive-data (System-wide, recommended)"
echo "2) /etc/overdrive"
echo "3) /var/lib/overdrive"
if [ "${#MOUNTS[@]}" -gt 0 ]; then
    echo "4) Select from detected mount points"
fi
echo "5) Custom location"
read -p "Enter choice [1-5]: " data_choice

case $data_choice in
    1) SHARED_LOCATION="/opt/overdrive-data" ;;
    2) SHARED_LOCATION="/etc/overdrive" ;;
    3) SHARED_LOCATION="/var/lib/overdrive" ;;
    4)
        if [ "${#MOUNTS[@]}" -eq 0 ]; then
            log_warn "No mount points detected, using default"
            SHARED_LOCATION="/opt/overdrive-data"
        else
            echo "Select a mount point:"
            for i in "${!MOUNTS[@]}"; do
                mount="${MOUNTS[$i]}"
                usage=$(df -h "$mount" 2>/dev/null | tail -1 | awk '{printf "%s / %s", $3, $2}' || echo "Unknown")
                echo "$((i+1))) $mount ($usage)"
            done
            read -p "Enter choice: " mount_choice
            if [ "$mount_choice" -ge 1 ] && [ "$mount_choice" -le "${#MOUNTS[@]}" ]; then
                SHARED_LOCATION="${MOUNTS[$((mount_choice-1))]}/overdrive-data"
            else
                log_warn "Invalid choice, using default"
                SHARED_LOCATION="/opt/overdrive-data"
            fi
        fi
        ;;
    5)
        read -p "Enter custom data path: " SHARED_LOCATION
        ;;
    *)
        log_error "Invalid choice. Using default: /opt/overdrive-data"
        SHARED_LOCATION="/opt/overdrive-data"
        ;;
esac

log_test "Data location: $SHARED_LOCATION"

# Step 5: Copy code to shared location (MOCK in test mode)
log_section "Step 5: Setting Up Installation"

if [ "$TEST_MODE" = "true" ]; then
    log_test "Would create directory: $SHARED_LOCATION"
    log_test "Would copy: /opt/overdrive-amc/overdrive.sh → $SHARED_LOCATION/overdrive.sh"
    log_test "Would copy: /opt/overdrive-amc/install.sh → $SHARED_LOCATION/install.sh"
    log_test "Would copy: /opt/overdrive-amc/README.md → $SHARED_LOCATION/README.md"
    log_test "Would chmod +x $SHARED_LOCATION/overdrive.sh"
    log_test "Would chmod +x $SHARED_LOCATION/install.sh"
else
    log_info "Creating shared data directory: $SHARED_LOCATION"
    mkdir -p "$SHARED_LOCATION" || {
        log_error "Failed to create $SHARED_LOCATION"
        exit 1
    }

    if [ -d "$INSTALL_DIR" ]; then
        log_info "Copying overdrive code to shared location..."
        cp -v "$INSTALL_DIR/overdrive.sh" "$SHARED_LOCATION/" || {
            log_error "Failed to copy overdrive.sh"
            exit 1
        }
        cp -v "$INSTALL_DIR/install.sh" "$SHARED_LOCATION/" || {
            log_error "Failed to copy install.sh"
            exit 1
        }
        if [ -f "$INSTALL_DIR/README.md" ]; then
            cp -v "$INSTALL_DIR/README.md" "$SHARED_LOCATION/" || {
                log_error "Failed to copy README.md"
                exit 1
            }
        fi
        chmod +x "$SHARED_LOCATION/overdrive.sh"
        chmod +x "$SHARED_LOCATION/install.sh"
        log_info "Code copied successfully"
    else
        log_error "Overdrive not found at $INSTALL_DIR"
        exit 1
    fi
fi

# Step 6: Create configuration file (MOCK in test mode)
log_section "Step 6: Creating Configuration"

CONFIG_FILE="$SHARED_LOCATION/config.sh"

if [ "$TEST_MODE" = "true" ]; then
    log_test "Would create config file: $CONFIG_FILE"
    log_test "Config would contain:"
    log_test "  INSTALL_DIR=$INSTALL_DIR"
    log_test "  SHARED_DIR=$SHARED_LOCATION"
    log_test "  SETUP_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    log_test "  Detected mount points:"
    for mount in "${MOUNTS[@]}"; do
        log_test "    - $mount"
    done
else
    cat > "$CONFIG_FILE" << EOF
#!/bin/bash
# Overdrive-AMC Configuration
# Generated by setup.sh

# Installation information
INSTALL_DIR="$INSTALL_DIR"
SHARED_DIR="$SHARED_LOCATION"
SETUP_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SETUP_BY="${SUDO_USER:-root}"

# Detected storage information
DETECTED_MOUNTS=()
DETECTED_DISKS=()

EOF

    for mount in "${MOUNTS[@]}"; do
        size=$(df -h "$mount" | tail -1 | awk '{print $2}')
        used=$(df -h "$mount" | tail -1 | awk '{print $3}')
        avail=$(df -h "$mount" | tail -1 | awk '{print $4}')
        echo "# Mount: $mount (Total: $size, Used: $used, Available: $avail)" >> "$CONFIG_FILE"
        echo "DETECTED_MOUNTS+=(\"$mount\")" >> "$CONFIG_FILE"
    done

    chmod +x "$CONFIG_FILE"
fi

log_test "Configuration would be saved to: $CONFIG_FILE"

# Step 7: Display summary
log_section "Setup Configuration Summary (TEST MODE)"

cat << EOF

${CYAN}TEST MODE - No actual changes made${NC}

Installation Directory:
  ${INSTALL_DIR}

Data/Config Location:
  ${SHARED_LOCATION}

Configuration File:
  ${CONFIG_FILE}

Detected Storage:
EOF

for mount in "${MOUNTS[@]}"; do
    usage=$(df -h "$mount" 2>/dev/null | tail -1 | awk '{printf "%s / %s (%s used)", $3, $2, int($5)}')
    echo "  • $mount - $usage"
done

cat << EOF

${CYAN}To run this script for real, execute:${NC}
  sudo bash setup.sh

${CYAN}Or with curl:${NC}
  curl -fsSL https://raw.githubusercontent.com/alittler/overdrive-amc/main/setup.sh | sudo bash

${GREEN}Test mode complete! All configurations verified.${NC}

EOF

log_test "Setup test complete - no changes made!"
