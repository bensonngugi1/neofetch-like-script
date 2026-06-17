#!/usr/bin/env bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
CYAN='\033[0;36m'
CYAN_B='\033[0;95m'
NC='\033[0m'
get_battery_advanced() {
    BAT_PATH=$(ls /sys/class/power_supply/ | grep BAT | head -n 1)

    [[ -z "$BAT_PATH" ]] && echo "No Battery" && return

    CAPACITY=$(cat /sys/class/power_supply/$BAT_PATH/capacity)
    STATUS=$(cat /sys/class/power_supply/$BAT_PATH/status)

    #  AUTO battery model 
    MODEL=$(cat /sys/class/power_supply/$BAT_PATH/model_name 2>/dev/null)

    # fallback if empty
    [[ -z "$MODEL" ]] && MODEL="Battery"

    # AC detection
    AC_STATUS="Disconnected"
    for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do
        [[ -f "$ac/online" && "$(cat "$ac/online")" == "1" ]] && AC_STATUS="AC Connected"
    done

    # colors
    RESET="\e[0m"
    RED="\e[1;31m"
    YELLOW="\e[1;33m"
    GREEN="\e[1;32m"

    # gradient simulation (block-based)
    FULL=20
    FILLED=$((CAPACITY * FULL / 100))
    EMPTY=$((FULL - FILLED))

    BAR=""

    for ((i=0; i<FILLED; i++)); do
        if (( i < FULL/3 )); then
            BAR+="${RED}█"
        elif (( i < FULL*2/3 )); then
            BAR+="${YELLOW}█"
        else
            BAR+="${GREEN}█"
        fi
    done

    BAR+="${RESET}"

    for ((i=0; i<EMPTY; i++)); do
        BAR+="░"
    done

    echo "${MODEL}: ${CAPACITY}% [${BAR}] [$AC_STATUS]"
  }
get_disk_root() {
    # Raw values
    read size used avail usep mount <<< "$(df -BG / | tail -1 | awk '{print $2, $3, $4, $5, $6}')"
    fs=$(df -T / | tail -1 | awk '{print $2}')

    # Clean formatting (remove G from df output)
    size="${size%G}"
    used="${used%G}"

    printf "Disk (/): %s GiB / %s GiB (%s) - %s\n" \
        "$used" "$size" "$usep" "$fs"
  }
get_packages() {
    COUNT=$(dpkg --get-selections 2>/dev/null | wc -l)
    echo "Packages: $COUNT (dpkg)"
}


# Header
echo -e "${CYAN}================================================${NC}"
echo -e "${YELLOW}          $(whoami)@$(hostname)${NC}"
echo -e "${CYAN}================================================${NC}"


echo -e "${WHITE}SYSTEM UPTIME: ${RED}$(uptime -p) "
echo -e "${WHITE}CURRENT DIRECTORY: ${RED}$(pwd)"
echo -e "${WHITE}YOUR IP ADDRESS: ${RED}$(ip -o -4 addr show wlo1 | awk '{print $4}'| cut -f1)"
echo -e "${WHITE}BATTERY STATUS: ${RED}$(get_battery_advanced)"
echo -e "${WHITE}OPERATING SYSTEM: ${RED}$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')"
echo -e "${WHITE}SYSTEM DISK: ${RED}$(get_disk_root)"
echo -e "${WHITE}PACKAGES: ${RED}$(get_packages)"
echo -e "${WHITE}KERNEL: ${RED}$(uname -r)"
echo -e "${WHITE}SWAP MEM: ${RED}$(free -h | awk '/Swap:/ {print "Swap: "$3" / "$2" ("$3/$2*100"%)"}')"
echo -e "${WHITE}RAM: ${RED}$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {
    used=t-a;
    printf "Memory: %.2f GiB / %.2f GiB (%.0f%%)\n", used/1024/1024, t/1024/1024, (used/t)*100
  }' /proc/meminfo)"

echo -e "${WHITE}SHELL: ${RED}$(bash --version | head -n1 | awk '{print $1, $4}')"
echo -e "${WHITE}DISPLAY: ${RED}$(xrandr | awk '/ connected/ {print $3, $4 "Hz"}')"
echo -e "${WHITE}GPU: ${RED}$(lspci | grep -i vga | cut -d: -f3 | sed 's/^ //') "
cpu=$(lscpu | awk -F: '/Model name/ {print $2}' | xargs)
echo -e "${WHITE}CPU: ${RED}$cpu ($(nproc))"


      echo -e                                    "${CYAN}©️ Created by Benson Ngugi.Feel free to modify. ${NC}  "
