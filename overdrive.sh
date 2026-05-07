#!/bin/bash

# --- RELIABLE PATH CAPTURE ---
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"

# --- DIALOG COLOUR SCHEME ---
export DIALOGRC_FILE="$HOME/.dialogrc_media"
cat <<EOF > "$DIALOGRC_FILE"
use_shadow = ON
use_colors = ON
screen_color = (CYAN,BLUE,ON)
dialog_color = (BLACK,WHITE,OFF)
title_color = (BLUE,WHITE,ON)
border_color = (WHITE,WHITE,ON)
button_active_color = (WHITE,BLUE,ON)
button_inactive_color = (BLACK,WHITE,OFF)
form_item_readonly_color = (CYAN,WHITE,ON)
EOF
export DIALOGRC="$DIALOGRC_FILE"

# --- CONFIG & CACHING ---
ENV_CACHE="$HOME/.media_bot.cache"
[[ -f "$ENV_CACHE" ]] && source "$ENV_CACHE"

# Defaults
: "${DIR_INPUT:=/mnt/Media/Torrents/finished}"
: "${DIR_TV:=/mnt/TV_Shows/TV Shows}"
: "${DIR_MOVIES:=/mnt/Media/Movies}"
: "${FMT_TV:={n}/{'Season '+s}/{n} - {s00e00}}"
: "${FMT_MOVIE:={n} ({y})}"

FB_LOG="$HOME/amc.log"
BBB_URL="https://webtorrent.io/torrents/big-buck-bunny.torrent"
LAN_IP=$(hostname -I | awk '{print $1}')
HOST_IP=${LAN_IP:-"127.0.0.1"}
QBIT_URL="http://${HOST_IP}:8181"
PLEX_URL="http://${HOST_IP}:32400"

# --- THE AUTOMATION HOOK ---
if [[ "$1" == "--auto-filebot" ]]; then
    filebot -script fn:amc --output "/" --action move -non-strict \
        --def ut_dir="$DIR_INPUT" ut_kind="multi" \
        --def "seriesFormat=$DIR_TV/$FMT_TV" \
        --def "movieFormat=$DIR_MOVIES/$FMT_MOVIE" \
        plex="localhost:$CACHE_PLEX" \
        pushover="$CACHE_PUSH_USER:$CACHE_PUSH_TOKEN" \
        gmail="$CACHE_GMAIL_USER:$CACHE_GMAIL_PASS" 2>&1 | tee -a "$FB_LOG"
    exit 0
fi

# --- HELPERS ---
msg() { dialog --title " AndrewNAS " --msgbox "$1" 20 85; }
get_free_space() { df -h "$1" | awk 'NR==2 {print $4}' 2>/dev/null || echo "N/A"; }

qbit_login() {
    local login_out=$(curl -s -i -X POST "$QBIT_URL/api/v2/auth/login" \
         -d "username=$CACHE_QBIT_USER&password=$CACHE_QBIT_PASS")
    echo "$login_out" | grep -oP 'SID=\K[^;]+' > /tmp/qbit_sid
}

while true; do
    MEDIA_SPACE=$(get_free_space "/mnt/Media")
    exec 3>&1
    selection=$(dialog --backtitle "AndrewNAS | Media Free: $MEDIA_SPACE" \
        --title " MAIN MENU " --clear --cancel-label "Exit" \
        --menu "Select an operation:" 24 85 16 \
        "---" "[ SETUP & CONFIG ]" \
        "S1" "Install Dependencies" \
        "S2" "Set API Credentials" \
        "S3" "Configure Folders & Naming" \
        "S4" "IMPORT CONFIG FROM PASTE" \
        "---" "[ QBITTORRENT ]" \
        "Q1" "Optimize qBit (RSS & Script Hook)" \
        "---" "[ TEST SUITE ]" \
        "T1" "STEP 1: RUN BBB TEST DOWNLOAD" \
        "T2" "STEP 2: DELETE BBB TEST FILES (Manual)" \
        "---" "[ FILEBOT SECTION ]" \
        "F1" "Live Download Monitor" \
        "F2" "Manual Filebot Run" \
        "F4" "VIEW GENERATED COMMAND" \
        "---" "[ MAINTENANCE ]" \
        "M1" "Clear Logs and Temp Files" \
        "M2" "BACKUP CONFIG TO EMAIL" \
        "RE" "RELOAD SCRIPT" \
        "00" "EXIT" 2>&1 1>&3)
    exit_status=$?
    exec 3>&-

    [[ $exit_status != 0 || "$selection" == "00" ]] && clear && exit 0

    case "$selection" in
        "S1")
            clear
            echo "Installing essential tools..."
            sudo apt update && sudo apt install -y curl jq swaks dialog filebot
            msg "Dependencies installed." ;;

        "S2")
            exec 3>&1
            mapfile -t input < <(dialog --title " API Setup " --form "Fill all credentials:" 20 75 0 \
                "Plex Token:" 1 1 "$CACHE_PLEX" 1 22 45 0 \
                "Push User Key:" 2 1 "$CACHE_PUSH_USER" 2 22 45 0 \
                "Push App Token:" 3 1 "$CACHE_PUSH_TOKEN" 3 22 45 0 \
                "Gmail User:" 4 1 "$CACHE_GMAIL_USER" 4 22 45 0 \
                "Gmail Pass:" 5 1 "$CACHE_GMAIL_PASS" 5 22 45 0 \
                "qBit User:" 6 1 "$CACHE_QBIT_USER" 6 22 45 0 \
                "qBit Pass:" 7 1 "$CACHE_QBIT_PASS" 7 22 45 0 \
                "Sudo Pass:" 8 1 "$CACHE_SUDO" 8 22 45 0 2>&1 1>&3)
            exec 3>&-
            if [[ -n "${input[0]}" ]]; then
                {
                    printf "export CACHE_PLEX=%q\n" "${input[0]}"
                    printf "export CACHE_PUSH_USER=%q\n" "${input[1]}"
                    printf "export CACHE_PUSH_TOKEN=%q\n" "${input[2]}"
                    printf "export CACHE_GMAIL_USER=%q\n" "${input[3]}"
                    printf "export CACHE_GMAIL_PASS=%q\n" "${input[4]}"
                    printf "export CACHE_QBIT_USER=%q\n" "${input[5]}"
                    printf "export CACHE_QBIT_PASS=%q\n" "${input[6]}"
                    printf "export CACHE_SUDO=%q\n" "${input[7]}"
                    [[ -n "$DIR_INPUT" ]] && printf "export DIR_INPUT=%q\n" "$DIR_INPUT"
                    [[ -n "$DIR_TV" ]] && printf "export DIR_TV=%q\n" "$DIR_TV"
                    [[ -n "$DIR_MOVIES" ]] && printf "export DIR_MOVIES=%q\n" "$DIR_MOVIES"
                    [[ -n "$FMT_TV" ]] && printf "export FMT_TV=%q\n" "$FMT_TV"
                    [[ -n "$FMT_MOVIE" ]] && printf "export FMT_MOVIE=%q\n" "$FMT_MOVIE"
                } > "$ENV_CACHE"
                source "$ENV_CACHE"; msg "Credentials Saved."
            fi ;;

        "S3")
            exec 3>&1
            mapfile -t paths < <(dialog --title " Folder Config " --form "Define Paths:" 20 75 0 \
                "Input/Torrents:" 1 1 "$DIR_INPUT" 1 20 50 0 \
                "TV Library:" 2 1 "$DIR_TV" 2 20 50 0 \
                "Movie Library:" 3 1 "$DIR_MOVIES" 3 20 50 0 \
                "TV Format:" 4 1 "$FMT_TV" 4 20 50 0 \
                "Movie Format:" 5 1 "$FMT_MOVIE" 5 20 50 0 2>&1 1>&3)
            exec 3>&-
            if [[ -n "${paths[0]}" ]]; then
                {
                    [[ -n "$CACHE_PLEX" ]] && printf "export CACHE_PLEX=%q\n" "$CACHE_PLEX"
                    [[ -n "$CACHE_PUSH_USER" ]] && printf "export CACHE_PUSH_USER=%q\n" "$CACHE_PUSH_USER"
                    [[ -n "$CACHE_PUSH_TOKEN" ]] && printf "export CACHE_PUSH_TOKEN=%q\n" "$CACHE_PUSH_TOKEN"
                    [[ -n "$CACHE_GMAIL_USER" ]] && printf "export CACHE_GMAIL_USER=%q\n" "$CACHE_GMAIL_USER"
                    [[ -n "$CACHE_GMAIL_PASS" ]] && printf "export CACHE_GMAIL_PASS=%q\n" "$CACHE_GMAIL_PASS"
                    [[ -n "$CACHE_QBIT_USER" ]] && printf "export CACHE_QBIT_USER=%q\n" "$CACHE_QBIT_USER"
                    [[ -n "$CACHE_QBIT_PASS" ]] && printf "export CACHE_QBIT_PASS=%q\n" "$CACHE_QBIT_PASS"
                    [[ -n "$CACHE_SUDO" ]] && printf "export CACHE_SUDO=%q\n" "$CACHE_SUDO"
                    printf "export DIR_INPUT=%q\n" "${paths[0]}"
                    printf "export DIR_TV=%q\n" "${paths[1]}"
                    printf "export DIR_MOVIES=%q\n" "${paths[2]}"
                    printf "export FMT_TV=%q\n" "${paths[3]}"
                    printf "export FMT_MOVIE=%q\n" "${paths[4]}"
                } > "$ENV_CACHE"
                source "$ENV_CACHE"; msg "Paths Updated."
            fi ;;

        "S4")
            RAW_INPUT="/tmp/media_import.txt"
            dialog --title " Paste Content Below " --editbox "$RAW_INPUT" 20 85 2> "$RAW_INPUT"
            if [[ -s "$RAW_INPUT" ]]; then
                grep -E "^export (CACHE_|DIR_|FMT_)" "$RAW_INPUT" | sed "s/^export //g" | sed "s/'//g" > "/tmp/filtered_vars.txt"
                if [[ -s "/tmp/filtered_vars.txt" ]]; then
                    while IFS='=' read -r key value; do
                        [[ -n "$key" ]] && printf "export %s=%q\n" "$key" "$value"
                    done < "/tmp/filtered_vars.txt" > "$ENV_CACHE"
                    rm "$RAW_INPUT" "/tmp/filtered_vars.txt"
                    source "$ENV_CACHE"
                    msg "IMPORT SUCCESSFUL"
                fi
            fi ;;

        "T1")
            qbit_login; sid=$(cat /tmp/qbit_sid)
            curl -s -X POST "$QBIT_URL/api/v2/torrents/add" -H "Cookie: SID=$sid" -F "urls=$BBB_URL"
            msg "BBB TEST STARTED. Use Plex/File Manager to verify. Use T2 to delete when done." ;;

        "T2")
            qbit_login; sid=$(cat /tmp/qbit_sid)
            BBB_HASH=$(curl -s -X GET "$QBIT_URL/api/v2/torrents/info" -H "Cookie: SID=$sid" | jq -r '.[] | select(.name | contains("Big Buck Bunny")) | .hash')
            if [[ -n "$BBB_HASH" ]]; then
                curl -s -X POST "$QBIT_URL/api/v2/torrents/delete" -H "Cookie: SID=$sid" -d "hashes=$BBB_HASH&deleteFiles=true"
            fi
            rm -rf "$DIR_MOVIES/Big Buck Bunny (2008)"
            curl -s -X GET "$PLEX_URL/library/sections/all/refresh?X-Plex-Token=$CACHE_PLEX"
            msg "MANUAL PURGE COMPLETE." ;;

        "F1") clear; watch -n 5 "ls -R \"$DIR_INPUT\"" ;;

        "F2")
            clear; echo "Running manual FileBot process..."
            bash "$SCRIPT_PATH" --auto-filebot
            read -p "Done. Press Enter." ;;

        "F4")
            PREVIEW="filebot -script fn:amc --output \"/\" --action move -non-strict --def ut_dir=\"$DIR_INPUT\" --def \"seriesFormat=$DIR_TV/$FMT_TV\" --def \"movieFormat=$DIR_MOVIES/$FMT_MOVIE\""
            dialog --title " Preview " --msgbox "$PREVIEW" 18 85 ;;

        "M1")
            rm -f "$FB_LOG" /tmp/qbit_sid
            msg "Logs and Temp Files Cleared." ;;

        "Q1")
            qbit_login; sid=$(cat /tmp/qbit_sid)
            trackers=$(curl -s https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt | grep -v '^$')
            json=$(jq -n --arg tr "$trackers" --arg sp "$SCRIPT_PATH" \
                '{"rss_enabled":true,"rss_auto_downloading_enabled":true,"add_trackers":$tr,"add_trackers_enabled":true,"incomplete_files_ext":true,"autorun_enabled":true,"autorun_program":("bash "+$sp+" --auto-filebot")}')
            curl -s -X POST "$QBIT_URL/api/v2/app/setPreferences" -H "Cookie: SID=$sid" -d "json=$json"
            msg "QBITTORRENT OPTIMIZATION COMPLETE" ;;

        "M2")
            if [[ -z "$CACHE_GMAIL_USER" || -z "$CACHE_GMAIL_PASS" ]]; then
                msg "Error: Set Gmail credentials in S2."
            else
                swaks --to "$CACHE_GMAIL_USER" --from "$CACHE_GMAIL_USER" \
                    --server smtp.gmail.com:587 --auth LOGIN \
                    --auth-user "$CACHE_GMAIL_USER" --auth-password "$CACHE_GMAIL_PASS" -tls \
                    --header "Subject: AndrewNAS Config Backup" \
                    --body "$(cat "$ENV_CACHE")"
                msg "Backup sent to $CACHE_GMAIL_USER"
            fi ;;

        "RE") exec bash "$SCRIPT_PATH" ;;
        "00") clear && exit 0 ;;
    esac
done
