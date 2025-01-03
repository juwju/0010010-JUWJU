#!/bin/bash



HardwareSummary() {
    echo -e "${BLUE}============================================================"
    echo -e "${GREEN} SYSTEM & CRYPTED NETWORK CAPACITIES"
    echo -e "${BLUE}============================================================"
    echo -e "${BLUE}MINIMUM REQUIREMENTS"

    # Check RAM
    total_mem=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_mem_mb=$((total_mem / 1024))
    if (( total_mem_mb >= 2000 )); then
        echo -e "${BLUE}Minimum 2GB RAM:                 ${GREEN}OK${NC}"
    else
        echo -e "${BLUE}Minimum 2GB RAM:                 ${RED}NO${NC}"
        exit 1
    fi
    # Check Disk Space
    free_disk=$(df / --output=avail | tail -n 1)
    free_disk_mb=$((free_disk / 1024))
    if (( free_disk_mb >= 10240 )); then
        echo -e "${BLUE}Minimum 10GB free disk space:    ${GREEN}OK${NC}"
    else
        echo -e "${BLUE}Minimum 10GB free disk space:    ${RED}NO${NC}"
        exit 1
    fi
    # Check Internet Connection
    if ping -c 1 -q google.com &>/dev/null; then
        echo -e "${BLUE}Active internet connection:      ${GREEN}OK${NC}"
    else
        echo -e "${BLUE}Active internet connection:      ${RED}NO${NC}"
        exit 1
    fi

    echo ""
}


HardwareSetup() {
    SetupGPU
    #HardwareSummary
}