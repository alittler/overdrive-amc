#!/bin/bash

# --- INSTALLATION BLOCK WITH ASCII ART ---
if [[ "$1" == "--install" ]]; then
    CYAN='\033[0;36m'; BLUE='\033[1;34m'; GOLD='\033[1;33m'; GREEN='\033[1;32m'
    RED='\033[1;31m'; GREY='\033[0;90m'; WHITE='\033[1;37m'; NC='\033[0m'

    # ASCII ART HEADER
    echo -e "${BLUE}"
    echo "                  ⣶⣿⣶⣦⣄⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣤⣶⣾⣿⣿⣷"
    echo "                  ⣿⣿⣿⣿⣿⠿⠿⠿⣿⣿⣿⣿⠿⠿⠿⢿⣿⣿⣿⣿⣿"
    echo "       ⢀⡀⣄      ⣿⣿⠟⠉⠀⢀⣀⠀⠀⠈⠉⠀⠀⣀⣀⠀⠀⠙⢿⣿⣿"
    echo "    ⣀⣶⣿⣿⣿⣾⣇   ⢀⣿⠃⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠹⣿"
    echo "    ⢻⣿⣿⣿⣿⣿⣿⣷⣄ ⣼⡏⠀⠀⠀⣀⣀⣉⠉⠩⠭⠭⠭⠥⠤⢀⣀⣀⠀⠀⠀⢻⡇"
    echo "    ⣸⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⣿⠷⠒⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠑⠒⠼⣧"
    echo "    ⢹⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣦⣀"
    echo "    ⢸⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣷⣦⣀"
    echo "    ⠈⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣷⣄"
    echo "     ⢹⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣷⣄"
    echo "      ⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣧⡀"
    echo "      ⢠⣿⣿⣿⣿⣿⣶⣤⣄⣠⣤⣤⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷"
    echo "      ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧"
    echo "    ⣀ ⢸⡿⠿⣿⡿⠋⠉⠛⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠉⠀⠻⠿⠟⠉⢙⣿⣿⣿⣿⣿⣿⡇"
    echo "    ⢿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀��⠈⠻⠿⢿⡿⣿⠳"
    echo "    ⡞⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣇⡀"
    echo " ⢀⣸⣀⡀⠀⠀⠀⠀⣠⣴⣾⣿⣷⣆⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⣰⣿⣿⣿⣿⣷⣦⠀⠀⠀⠀⢿⣿⠿⠃"
    echo " ⠘⢿⡿⠃⠀⠀⠀⣸⣿⣿⣿⣿⣿⡿⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⢻⣿⣿⣿⣿⣿⣿⠂⠀⠀⠀⡸⠁"
    echo "    ⠳⣄⠀⠀⠀⠹⣿⣿⣿⡿⠛⣠⠾⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⠳⣄⠙⠛⠿⠿⠛⠉⠀⠀⣀⠜⠁"
    echo "      ⠈⠑⠢⠤⠤⠬⠭⠥⠖⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠒⠢⠤⠤⠤⠒⠊⠁"
    echo -e "${NC}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Install logic
    echo
    read -rp "Enter the full path where you want to install overdrive.sh (e.g. /usr/local/bin/overdrive.sh): " TARGET
    if [[ -z "$TARGET" ]]; then
        echo "Install path required."
        exit 1
    fi
    echo "Copying overdrive.sh to $TARGET ..."
    curl -fsSL "https://raw.githubusercontent.com/alittler/overdrive-amc/main/overdrive.sh" -o "$TARGET"
    chmod +x "$TARGET"
    echo "overdrive.sh successfully installed to $TARGET"
    exit 0
fi

# --- 1. DEPENDENCY & DIRECTORY INITIALIZATION ---
DEP_LOG="/home/$(whoami)/.media_bot_deps"
REQUIRED_PKGS=("swaks" "curl" "ca-certificates" "wget")

check_dependencies() {
    MISSING_PKGS=()
    for pkg in "${REQUIRED_PKGS[@]}"; do
        if ! command -v "$pkg" &> /dev/null; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        echo -e "\033[1;33m[!] Installing missing tools: ${MISSING_PKGS[*]}\033[0m"
        sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}"
    fi
    
    if [[ ! -f "$DEP_LOG" ]]; then
        touch "$DEP_LOG"
        echo "Verified: $(date)" > "$DEP_LOG"
    fi
}

# Run check if log is missing
[[ ! -f "$DEP_LOG" ]] && check_dependencies

# --- 2. COLORS ---
CYAN='\033[0;36m'; BLUE='\033[1;34m'; GOLD='\033[1;33m'; GREEN='\033[1;32m'
RED='\033[1;31m'; GREY='\033[0;90m'; WHITE='\033[1;37m'; NC='\033[0m'

# --- 3. PATHS & CONFIG ---
SCRIPT_PATH=$(readlink -f "$0")
CURRENT_USER=$(whoami)
LOCAL_IP=$(hostname -I | awk '{print $1}' | cut -d' ' -f1)
ENV_FILE="/home/$CURRENT_USER/.media_bot.env"
PGP_FILE="/home/$CURRENT_USER/.media_bot.pgp"
STORAGE_CACHE="/tmp/.media_storage_cache"

# --- 4. STORAGE LOGIC ---
# ... (Rest of your script as you posted: get_grouped_storage, update_yaml_config, email_backup, run_processor, etc) ...
# --- 5. AUTOMATED YAML FIND & INJECT ---
update_yaml_config() {
    : # (Your code)
}
# --- 6. CORE FUNCTIONS ---
email_backup() {
    : # (Your code)
}
# ... (the rest of your code, unchanged) ...

# --- 7. UI HEADER ---
header() {
    : # (Your code for ASCII art and system bar)
}

show_qbittorrent_mappings() {
    containers=$(sudo docker ps -a --filter name=qbittorrent --format '{{.Names}}')
    if [ -z "$containers" ]; then
        echo "No containers named qbittorrent (running or stopped)"
        return
    fi

    for container in $containers; do
        echo
        echo "=== Container: $container ==="
        unset MAP_finished MAP_temp MAP_watching

        while read -r mapping; do
            host_path="${mapping% =>*}"
            cont_path="${mapping#*=> }"
            for sub in finished temp watching; do
                host_target="${host_path}/Torrents/$sub"
                if [ -d "$host_target" ]; then
                    cont_target="${cont_path}/Torrents/$sub"
                    eval "MAP_$sub='$cont_target'"
                    echo "Folder '$sub' --> Host: $host_target  |  Container: $cont_target"
                fi
            done
        done < <(sudo docker inspect "$container" --format '{{range .Mounts}}{{.Source}} => {{.Destination}}{{"\n"}}{{end}}')

        unset OVERDRIVE_PATH
        while read -r mapping; do
            host_path="${mapping% =>*}"
            cont_path="${mapping#*=> }"
            if [ -f "${host_path}/overdrive.sh" ]; then
                OVERDRIVE_PATH="${cont_path}/overdrive.sh"
                echo "Found overdrive.sh --> Host: $host_path/overdrive.sh | Container: $OVERDRIVE_PATH"
                break
            fi
        done < <(sudo docker inspect "$container" --format '{{range .Mounts}}{{.Source}} => {{.Destination}}{{"\n"}}{{end}}')

        if [ -z "$OVERDRIVE_PATH" ]; then
            echo "WARNING: overdrive.sh not found in any mapped volume, using fallback"
            OVERDRIVE_PATH="/overdrive.sh"
        fi

        echo
        echo "Suggested qBittorrent folders (Container paths):"
        echo "  Finished: ${MAP_finished:-/downloads}"
        echo "  Temp:     ${MAP_temp:-/temp}"
        echo "  Watching: ${MAP_watching:-/watching}"
        echo
        echo "AutoRun 'program=' string:"
        echo "  ${OVERDRIVE_PATH} \"%F\""
        echo
        echo "-----"
    done

    echo "No changes made to any files. Safe BETA output only."
}

# --- 8. MAIN LOOP ---
while true; do
    header
    echo -e "  ${CYAN}SETUP & CONFIGURATION${NC}"
    echo -e "  ${WHITE}[01]${NC} Update Environment & PGP"
    echo -e "  ${WHITE}[02]${NC} Show qBittorrent Setup String"
    echo -e "  ${WHITE}[03]${NC} ${GOLD}AUTO-INJECT AMC STRING INTO YAML${NC}"
    echo -e "  ${WHITE}[16]${NC} Show qBittorrent Folders & AutoRun string"
    echo -e "\n  ${CYAN}CORE PROCESSING${NC}"
    echo -e "  ${WHITE}[04]${NC} Run Move (Finished)\n  ${WHITE}[05]${NC} Run Move (Temp)\n  ${WHITE}[06]${NC} Forced Run (Ignore History)\n  ${WHITE}[07]${NC} Simulation Mode (Dry Run)"
    echo -e "\n  ${CYAN}SYSTEM & MAINTENANCE${NC}"
    echo -e "  ${WHITE}[08]${NC} View Logs\n  ${WHITE}[09]${NC} Scrub Junk Files\n  ${WHITE}[10]${NC} Wipe AMC History\n  ${WHITE}[11]${NC} Empty Finished/Temp\n  ${WHITE}[12]${NC} ${GOLD}SYSTEM UPGRADE${NC}"
    echo -e "\n  ${CYAN}ALERTS & TESTING${NC}"
    echo -e "  ${WHITE}[13]${NC} Test Notifications\n  ${WHITE}[14]${NC} Run Test Cycle\n  ${WHITE}[15]${NC} Trigger Configuration Backup"
    echo -e "\n  ${CYAN}SYSTEM${NC}\n  ${WHITE}[00]${NC} TERMINATE SESSION\n"
    echo -ne "  ${WHITE}SELECT OPTION:${NC} "; read -r choice

    case "$choice" in
        01|1) run_inline_setup ;;
        02|2) echo -e "\n${WHITE}filebot -script fn:amc \"/downloads\" --output \"/media\" --action move --conflict override -non-strict --def \"ut_dir=%F\" \"ut_kind=multi\" \"ut_title=%N\" \"ut_label=%L\"" && read -p "Enter..." res ;;
        03|3) update_yaml_config; read -p "Enter..." res ;;
        04|4) run_processor "move" "override" "$FINISHED_DIR" "false"; read -p "Enter..." res ;;
        05|5) run_processor "move" "override" "$TEMP_DIR" "false"; read -p "Enter..." res ;;
        06|6) run_processor "move" "override" "$FINISHED_DIR" "true"; read -p "Enter..." res ;;
        07|7) run_processor "test" "skip"; read -p "Enter..." res ;;
        08|8) tail -n 50 "$FINISHED_DIR/filebot_amc.log"; read -p "Enter..." res ;;
        09|9) find "$FINISHED_DIR" -type f -size -20M -delete; echo "Junk scrubbed."; sleep 1 ;;
        10)   rm "$FINISHED_DIR/amc_exclude.txt" 2>/dev/null; echo "History wiped."; sleep 1 ;;
        11)   sudo rm -rf "${FINISHED_DIR:?}"/*; sudo rm -rf "${TEMP_DIR:?}"/*; rm -f "$STORAGE_CACHE"; echo "Folders cleared."; read -p "Enter..." res ;;
        12)   echo -e "${GOLD}[!] Starting Full System Maintenance...${NC}"
              echo -e "${CYAN}[1/4] Updating Package Lists...${NC}"
              sudo apt update
              echo -e "${CYAN}[2/4] Checking for Upgradeable Packages...${NC}"
              apt list --upgradeable
              echo -e "${CYAN}[3/4] Performing System Upgrade...${NC}"
              sudo apt upgrade -y
              echo -e "${CYAN}[4/4] Forcing Re-installation of Dependencies...${NC}"
              sudo apt install -y "${REQUIRED_PKGS[@]}"
              check_dependencies
              echo -e "${GREEN}✓ Maintenance Complete.${NC}"
              read -p "Press Enter to return to menu..." res ;;
        13)   email_backup; echo "Alerts triggered."; read -p "Enter..." res ;;
        14)   wget -P "$WATCHING_DIR" "https://webtorrent.io/torrents/big-buck-bunny.torrent"; read -p "Test started..." res ;;
        15)   email_backup; read -p "Backup sent." res ;;
        16)   show_qbittorrent_mappings; read -p "Press Enter..." res ;;
        00|0) exit 0 ;;
        *) [[ -n "$choice" ]] && echo -e "${RED}Invalid selection.${NC}" && sleep 0.5 ;;
    esac
done
