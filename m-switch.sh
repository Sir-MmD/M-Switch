#!/bin/bash
#MmD

# Function to check if the user is root
check_root_user() {
  if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as ${RED}root${NC}."
    exit 1
  fi
}

# Function to check if the OS is Kali Linux
check_os_kali() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "kali" ]; then
      echo "This script must be run on ${RED}Kali Linux${NC}."
      exit 1
    fi
  else
    echo "OS information not found."
    exit 1
  fi
}

# Global variable for hostnames
declare -a hostnames=(
    "kali.download"
    "mirrors.jevincanders.net"
    "kali.cs.nycu.edu.tw"
    "mirror.kku.ac.th"
    "mirrors.neusoft.edu.cn"
    "kali.darklab.sh"
    "kali.mirror.garr.it"
    "kali.mirror.rafal.ca"
    "mirrors.netix.net"
    "mirror.freedif.org"
    "mirror.aktkn.sg"
    "mirrors.ocf.berkeley.edu"
    "mirror1.sox.rs"
    "mirror.pyratelan.org"
    "mirror.johnnybegood.fr"
    "ftp.free.fr"
    "archive-4.kali.org"
    "ftp.halifax.rwth-aachen.de"
    "mirror.netcologne.de"
    "free.nchc.org.tw"
    "mirror.accuris.ca"
    "mirror.twds.com.tw"
    "mirror.init7.net"
    "mirror.0xem.ma"
    "mirror.vinehost.net"
    "xsrv.moratelindo.io"
    "mirror.primelink.net.id"
    "mirror.cspacehostings.com"
    "mirror.leitecastro.com"
    "mirror.cedia.org.ec"
    "mirrors.ustc.edu.cn"
    "elmirror.cl"
    "ftp.nluug.nl"
    "mirror.serverius.net"
    "mirror.ufro.cl"
    "repo.jing.rocks"
    "mirrors.dotsrc.org"
    "ftp.ne.jp"
    "ftp.jaist.ac.jp"
    "ftp.riken.jp"
    "mirror.lagoon.nc"
    "ftp.yz.yamagata-u.ac.jp"
    "ftp.belnet.be"
    "quantum-mirror.hu"
    "kali.koyanet.lv"
    "mirror.2degrees.nz"
    "mirror.accum.se"
    "wlglam.fsmg.org.nz"
    "hlzmel.fsmg.org.nz"
    "mirror.truenetwork.ru"
    "ftp.cc.uoc.gr"
    "mirror.amuksa.com"
    "kali.itsec.am"
    "kali.mirror2.gnc.am"
    "kali.mirror1.gnc.am"
    "md.mirrors.hacktegic.com"
    "mirror.math.princeton.edu"
    "fastmirror.pp.ua"
)

# ANSI color codes
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
NC=$(tput sgr0) # No Color

set_mirror_auto() {
    backup_sources_list
    
    # Call test_mirror function to find the best mirror
    test_mirror
    
    if [ -n "$best_hostname" ]; then
        # Update sources.list with the best hostname
        sudo sed -i "s|deb http://[^/]\+/kali|deb http://$best_hostname/kali|g" /etc/apt/sources.list
        echo ""
        echo "Updated /etc/apt/sources.list with the best mirror: ${BLUE}$best_hostname${NC}"
        echo ""
        # apt update
        apt update -y
        echo ""
        echo "${GREEN}Update complete! Enjoy!${NC}"
        echo ""
    else
        echo "Failed to find a suitable mirror."
    fi
}

# Function to prompt user for apt update
prompt_apt_update() {
    read -p "Do you want to run 'apt update' now? (y/n): " update_choice
    case "$update_choice" in
        [yY]|[yY][eE][sS])
            sudo apt update
            echo "apt update has been executed."
            ;;
        *)
            echo "You can run 'apt update' later to apply the changes."
            ;;
    esac
}

# Function to set mirror manually
set_mirror_manual() {
    # Display each hostname with a number for selection
    for i in "${!hostnames[@]}"; do
        echo "$((i+1)). ${hostnames[$i]}"
    done
    read -p "Select a hostname: " num
    if [ $num -ge 1 ] && [ $num -le ${#hostnames[@]} ]; then
        selected_hostname=${hostnames[$((num-1))]}
        echo "Hostname set to: ${BLUE}$selected_hostname${NC}"
        
        # Search for and replace the selected hostname in sources.list
        sudo sed -i "s|deb http://[^/]\+/kali|deb http://$selected_hostname/kali|g" /etc/apt/sources.list
        echo ""
        echo "Updated /etc/apt/sources.list with the selected hostname."
        echo ""
        # Prompt user to run apt update
        prompt_apt_update
    else
        echo "Invalid number. Please enter a number from 1 to ${#hostnames[@]}."
        set_mirror_manual
    fi
}

best_hostname=""

# Function to test mirror
test_mirror() {
    echo ""
    echo "Testing mirrors connectivity:"
    echo ""
    # Variables to track OK and failed servers
    ok_count=0
    failed_count=0
    best_time=9999999
    
    for hostname in "${hostnames[@]}"; do
        echo -n "Testing connectivity to ${BLUE}$hostname${NC} "
        
        start_time=$(date +%s%N)  # Start time in nanoseconds
        
        if curl --max-time 5 --output /dev/null --silent --head --fail "$hostname"; then
            end_time=$(date +%s%N)  # End time in nanoseconds
            duration=$(( (end_time - start_time) / 1000000 ))  # Duration in milliseconds
            echo -e "${GREEN}OK${NC} ${duration}ms"
            ((ok_count++))
            
            # Check for the best hostname
            if [ $duration -lt $best_time ]; then
                best_time=$duration
                best_hostname=$hostname
            fi
        else
            echo -e "${RED}FAILED${NC}"
            ((failed_count++))
        fi
    done
    
    echo "------------------------"
    echo "${GREEN}OK Mirrors${NC}: $ok_count"
    echo "${RED}FAILED Mirrors${NC}: $failed_count"
    echo "Best Mirror: ${BLUE}$best_hostname${NC} with ${best_time}ms"
    echo "------------------------"
}

# Function to backup sources.list
backup_sources_list() {
    if [ -f /etc/apt/sources.list.backup ]; then
        echo ""
        echo "Backup of sources.list already exists: /etc/apt/sources.list.backup"
        echo ""
    else
        sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
        echo ""
        echo "Backup of sources.list created: /etc/apt/sources.list.backup"
        echo ""
    fi
}


# Function to restore sources.list
restore_sources_list() {
    sudo cp /etc/apt/sources.list.backup /etc/apt/sources.list
    echo ""
    echo "Restored sources.list from backup: /etc/apt/sources.list.backup"
    echo ""
}

# Display menu
display_menu() {
    echo ""
    echo "███    ███       ███████ ██     ██ ██ ████████  ██████ ██   ██ "
    echo "████  ████       ██      ██     ██ ██    ██    ██      ██   ██ "
    echo "██ ████ ██ ${RED}█████${NC} ███████ ██  █  ██ ██    ██    ██      ███████ "
    echo "██  ██  ██            ██ ██ ███ ██ ██    ██    ██      ██   ██ "
    echo "██      ██       ███████  ███ ███  ██    ██     ██████ ██   ██ "
    echo "                                                                "
    echo ""         
    echo "1. Update Mirror Automatically (Recommended)"
    echo "2. Update Mirror Manually"
    echo "3. Test Mirror Only"
    echo "4. Backup sources.list"
    echo "5. Restore sources.list"
    echo "6. Exit"
}

# Main script
while true; do
    check_root_user
    check_os_kali
    display_menu
    echo ""
    read -p "Enter your choice: " choice
    echo ""
    case $choice in
        1)
            set_mirror_auto
            ;;
        2)
            set_mirror_manual
            ;;
        3)
            test_mirror
            ;;
        4)
            backup_sources_list
            ;;
        5)
            restore_sources_list
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please enter a number from 1 to 6."
            ;;
    esac
done
