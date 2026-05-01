#!/bin/bash

# Fast self-installer: curl|bash support
if [[ "$1" == "--install" ]]; then
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

    [[ ! -f "$DEP_LOG" ]] && check_dependencies

    echo
    read -rp "Enter the full path where you want to install overdrive.sh (e.g. /usr/local/bin/overdrive.sh): " TARGET

    if [[ -z "$TARGET" ]]; then
        echo "Install path required."
        exit 1
    fi

    echo "Installing overdrive.sh to $TARGET ..."
    curl -fsSL "https://raw.githubusercontent.com/alittler/overdrive-amc/main/overdrive.sh" -o "$TARGET" &&
    chmod +x "$TARGET" &&
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

STORAGE_ROOT="/mnt/Media"
FINISHED_DIR="$STORAGE_ROOT/Torrents/finished"
TEMP_DIR="$STORAGE_ROOT/Torrents/temp"
WATCHING_DIR="$STORAGE_ROOT/Torrents/watching"
QB_CONTAINER="qbittorrent"

# Ensure target directories exist
mkdir -p "$FINISHED_DIR" "$TEMP_DIR" "$WATCHING_DIR"

# --- 4. STORAGE LOGIC ---
get_grouped_storage() {
    if [[ -f "$STORAGE_CACHE" ]]; then
        cat "$STORAGE_CACHE"
        return
    fi

    # Added requested empty line before loading message
    echo -e "\n  ${GREY}Loading storage statuses...${NC}"
    local storage_data=$(sudo docker inspect -f '{{range .Mounts}}{{.Source}} {{.Destination}}{{"\n"}}{{end}}' "$QB_CONTAINER" 2>/dev/null)

    if [[ -n "$storage_data" ]]; then
        local build_file="/tmp/storage_build.tmp"
        echo "$storage_data" | while read -r src dst; do
            [[ -z "$src" || ! -d "$src" ]] && continue
            local fs_id=$(df "$src" --output=source | tail -1)
            local label
            case "$src" in
                *TV_Shows*|*"TV Shows"*) label="TV_SHOWS" ;;
                *Media*)               label="MEDIA" ;;
                *DATA*)                label="DATA" ;;
                *)                     label=$(echo "$dst" | tr '[:lower:]' '[:upper:]' | sed 's/\///g') ;;
            esac
            [[ -z "$label" ]] && label="ROOT"
            echo "$fs_id|$label|$src"
        done | sort | {
            local current_disk=""; local labels=""; local first_path=""
            while read -r line; do
                local disk=$(echo "$line" | cut -d'|' -f1); local lbl=$(echo "$line" | cut -d'|' -f2); local path=$(echo "$line" | cut -d'|' -f3)
                if [[ "$disk" != "$current_disk" ]]; then
                    if [[ -n "$current_disk" ]]; then
                        stats=$(sudo df -h "$first_path" | awk 'NR==2 {print $5 " (" $4 " Free)"}')
                        printf "  ${WHITE}%-25s:${NC} %s\n" "$(echo "$labels" | sed 's/\/$//')" "$stats" >> "$build_file"
                    fi
                    current_disk="$disk"; labels="$lbl/"; first_path="$path"
                else [[ ! "$labels" =~ "$lbl" ]] && labels+="$lbl/"; fi
            done
            if [[ -n "$current_disk" ]]; then
                stats=$(sudo df -h "$first_path" | awk 'NR==2 {print $5 " (" $4 " Free)"}')
                printf "  ${WHITE}%-25s:${NC} %s\n" "$(echo "$labels" | sed 's/\/$//')" "$stats" >> "$build_file"
            fi
        }
        [[ -f "$build_file" ]] && mv "$build_file" "$STORAGE_CACHE"
        tput cuu1 && tput el; cat "$STORAGE_CACHE"
    else
        tput cuu1 && tput el; echo -e "  ${RED}No active storage mounts detected.${NC}"
    fi
}

# --- 5. AUTOMATED YAML FIND & INJECT ---
update_yaml_config() {
    echo -e "\n${GOLD}[!] SEARCHING FOR YOUR DOCKER COMPOSE FILE...${NC}"
    local yaml_dir=$(sudo docker inspect "$QB_CONTAINER" --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' 2>/dev/null)
    local yaml_path=""
    if [[ -d "$yaml_dir" ]]; then
        [[ -f "$yaml_dir/docker-compose.yaml" ]] && yaml_path="$yaml_dir/docker-compose.yaml"
        [[ -f "$yaml_dir/docker-compose.yml" ]] && yaml_path="$yaml_dir/docker-compose.yml"
    fi
    [[ -z "$yaml_path" ]] && yaml_path=$(sudo find / -name "docker-compose.y*ml" -exec sudo grep -l "image.*qbittorrent" {} + 2>/dev/null | head -n 1)

    if [[ -z "$yaml_path" ]]; then echo -e "${RED}✗ FAIL: File not found.${NC}"; return; fi
    echo -e "${GREEN}✓ TARGET ACQUIRED: $yaml_path${NC}"

    local cmd_string="filebot -script fn:amc \"/downloads\" --output \"/media\" --action move --conflict override -non-strict --def \"ut_dir=%F\" \"ut_kind=multi\" \"ut_title=%N\" \"ut_label=%L\""
    ! sudo grep -q "$SCRIPT_PATH" "$yaml_path" && sudo sed -i "/qbittorrent:/,/volumes:/ s|volumes:|volumes:\n      - $SCRIPT_PATH:/usr/local/bin/media_bot.sh|" "$yaml_path"
    if ! sudo grep -q "AMC_CMD" "$yaml_path"; then
        sudo sed -i "/qbittorrent:/,/environment:/ s|environment:|environment:\n      - AMC_CMD=$cmd_string|" "$yaml_path"
        echo -e "${GREEN}✓ STRING SUCCESSFULLY INJECTED.${NC}"
    else echo -e "${CYAN}i STRING ALREADY EXISTS.${NC}"; fi
    echo -e "${GOLD}[!] Run: sudo docker-compose -f $yaml_path up -d${NC}"
}

# --- 6. CORE FUNCTIONS ---
email_backup() {
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    if [[ -z "$GMAIL_USER" || -z "$GMAIL_PASS" ]]; then echo -e "${RED}✗ Email Failed: Credentials missing.${NC}"; return; fi
    echo -e "${GOLD}[!] Sending Backup Email...${NC}"
    local prm_cmd="filebot -script fn:amc \"/downloads\" --output \"/media\" --action move --conflict override -non-strict --def \"ut_dir=%F\" \"ut_kind=multi\" \"ut_title=%N\" \"ut_label=%L\""
    local body="ANDREWNAS BACKUP\nDate: $(date)\n\nENV:\n$(cat "$ENV_FILE")\n\nPGP:\n$(cat "$PGP_FILE")\n\nCMD: $prm_cmd"
    echo -e "$body" | swaks --to "$GMAIL_USER" --from "$GMAIL_USER" --server smtp.gmail.com --port 587 --auth LOGIN --auth-user "$GMAIL_USER" --auth-password "$GMAIL_PASS" --tls --header "Subject: AndrewNAS Backup" --body - > /dev/null 2>&1
}

run_processor() {
    local mode=$1; local conflict=$2; local target_dir=${3:-$FINISHED_DIR}; local force=$4
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    local action="move"; [[ "$mode" == "test" ]] && action="test"
    local ex_list="$FINISHED_DIR/amc_exclude.txt"; [[ "$force" == "true" ]] && ex_list="/dev/null"
    echo -e "${GOLD}[!] Launching FileBot...${NC}"
    JAVA_OPTS="-Djava.io.tmpdir=$TEMP_DIR" filebot -script fn:amc "$target_dir" --output "$STORAGE_ROOT" --action "$action" --conflict "$conflict" -non-strict --def excludeList="$ex_list" plex="$PLEX_TOKEN" seriesFormat="TV Shows/{n}/{'Season '+s}/{n} - {s00e00} - {t}" movieFormat="Movies/{n} ({y})/{n} ({y})"
    rm -f "$STORAGE_CACHE"
}

update_env() {
    local key=$1; local val=$2
    touch "$ENV_FILE"
    grep -q "^$key=" "$ENV_FILE" && sed -i "s|^$key=.*|$key='$val'|" "$ENV_FILE" || echo "$key='$val'" >> "$ENV_FILE"
}

run_inline_setup() {
    echo -e "\n${CYAN}SETUP OPTIONS:${NC}"
    echo -e "  ${WHITE}[A]${NC} Update keys individually"
    echo -e "  ${WHITE}[B]${NC} Bulk paste .env"
    echo -e "  ${WHITE}[C]${NC} Update PGP Key"
    echo -ne "  ${WHITE}SELECT:${NC} "
    read -r setup_choice
    case $setup_choice in
        B|b) echo "Paste .env and hit CTRL+D:"; cat > "$ENV_FILE" ;;
        C|c) echo "Paste PGP and hit CTRL+D:"; cat > "$PGP_FILE" ;;
        *) 
            echo -en "Plex Token: "; read -r p_token; [[ -n "$p_token" ]] && update_env "PLEX_TOKEN" "$p_token"
            echo -en "Gmail Address: "; read -r gm_u; [[ -n "$gm_u" ]] && update_env "GMAIL_USER" "$gm_u"
            echo -en "Gmail App Password: "; read -r gm_p; [[ -n "$gm_p" ]] && update_env "GMAIL_PASS" "$(echo "$gm_p" | tr -d ' ')"
            ;;
    esac
    email_backup
}

# --- 7. UI HEADER ---
header() {
    [[ -f "$ENV_FILE" ]] && source "$ENV_FILE"
    clear
    echo -e "${BLUE}"
    echo "                  ⣶⣿⣶⣦⣄⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣤⣶⣾⣿⣿⣷"
    echo "                  ⣿⣿⣿⣿⣿⠿⠿⠿⣿⣿⣿⣿⠿⠿⠿⢿⣿⣿⣿⣿⣿"
    echo "       ⢀⡀⣄      ⣿⣿⠟⠉⠀⢀⣀⠀⠀⠈⠉⠀⠀⣀⣀⠀⠀⠙⢿⣿⣿"
    echo "    ⣀⣶⣿⣿⣿⣾⣇   ⢀⣿⠃⠀⠀⠀⠀⢀⣀⡀⠀⠀⠀⣀⡀⠀⠀⠀⠀⠀⠹⣿"
    echo "    ⢻⣿⣿⣿⣿⣿⣿⣷⣄ ⣼⡏⠀⠀⠀⣀⣀⣉⠉⠩⠭⠭⠭⠥⠤⢀⣀⣀⠀⠀⠀⢻⡇"
    echo "    ⣸⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⣿⠷⠒⠋⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠑⠒⠼⣧"
    echo "    ⢹⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⣦⣀"
    echo "    ⢸⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣷⣦⣀"
    echo "    ⠈⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣷⣄"
    echo "     ⢹⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣷⣄"
    echo "      ⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣧⡀"
    echo "      ⢠⣿⣿⣿⣿⣿⣶⣤⣄⣠⣤⣤⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷"
    echo "      ⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧"
    echo "    ⣀ ⢸⡿⠿⣿⡿⠋⠉⠛⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠉⠀⠻⠿⠟⠉⢙⣿⣿⣿⣿⣿⣿⡇"
    echo "    ⢿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠈⠻⠿⢿⡿⣿⠳"
    echo "    ⡞⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣇⡀"
    echo " ⢀⣸⣀⡀⠀⠀⠀⠀⣠⣴⣾⣿⣷⣆⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⠀⣰⣿⣿⣿⣿⣷⣦⠀⠀⠀⠀⢿⣿⠿⠃"
    echo " ⠘⢿⡿⠃⠀⠀⠀⣸⣿⣿⣿⣿⣿⡿⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⢻⣿⣿⣿⣿⣿⣿⠂⠀⠀⠀⡸⠁"
    echo "    ⠳⣄⠀⠀⠀⠹⣿⣿⣿⡿⠛⣠⠾⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⠳⣄⠙⠛⠿⠿⠛⠉⠀⠀⣀⠜⠁"
    echo "      ⠈⠑⠢⠤⠤⠬⠭⠥⠖⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠒⠢⠤⠤⠤⠒⠊⠁"
    echo -e "${NC}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    [[ -f "$ENV_FILE" && -s "$ENV_FILE" ]] && CONF_STAT="${GREEN}ACTIVE${NC}" || CONF_STAT="${RED}OFFLINE${NC}"
    echo -e "${WHITE}  SYSTEM:${NC} $LOCAL_IP   ${WHITE}CONFIG:${NC} $CONF_STAT"
    get_grouped_storage
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# --- 8. MAIN LOOP ---
while true; do
    header
    echo -e "  ${CYAN}SETUP & CONFIGURATION${NC}"
    echo -e "  ${WHITE}[01]${NC} Update Environment & PGP\n  ${WHITE}[02]${NC} Show qBittorrent Setup String\n  ${WHITE}[03]${NC} ${GOLD}AUTO-INJECT AMC STRING INTO YAML${NC}"
    echo -e "\n  ${CYAN}CORE PROCESSING${NC}"
    echo -e "  ${WHITE}[04]${NC} Run Move (Finished)\n  ${WHITE}[05]${NC} Run Move (Temp)\n  ${WHITE}[06]${NC} Forced Run (Ignore History)\n  ${WHITE}[07]${NC} Simulation Mode (Dry Run)"
    echo -e "\n  ${CYAN}SYSTEM & MAINTENANCE${NC}"
    echo -e "  ${WHITE}[08]${NC} View Logs\n  ${WHITE}[09]${NC} Scrub Junk Files\n  ${WHITE}[10]${NC} Wipe AMC History\n  ${WHITE}[11]${NC} Empty Finished/Temp\n  ${WHITE}[12]${NC} ${GOLD}SYSTEM UPGRADE & RE-VERIFY DEPS${NC}"
    echo -e "\n  ${CYAN}ALERTS & TESTING${NC}"
    echo -e "  ${WHITE}[13]${NC} Test Notifications\n  ${WHITE}[14]${NC} Run Test Cycle\n  ${WHITE}[15]${NC} Trigger Configuration Backup"
    echo -e "\n  ${CYAN}SYSTEM${NC}\n  ${WHITE}[00]${NC} TERMINATE SESSION\n"
    echo -ne "  ${WHITE}SELECT OPTION:${NC} "; read -r choice

    case "$choice" in
        01|1) run_inline_setup ;;
        02|2) echo -e "\n${WHITE}filebot -script fn:amc \"/downloads\" --output \"/media\" --action move --conflict override -non-strict --def \"ut_dir=%F\" \"ut_kind=multi\" \"ut_title=%N\" \"ut_label=%L\"${NC}"; read -p "Enter..." res ;;
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
        00|0) exit 0 ;;
        *) [[ -n "$choice" ]] && echo -e "${RED}Invalid selection.${NC}" && sleep 0.5 ;;
    esac
done
