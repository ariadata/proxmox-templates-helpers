#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Spinner characters
SPINNER="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

# Function to show spinner
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Message functions
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    local text="$1"
    local width=50
    local padding=$(( (width - ${#text}) / 2 ))
    echo
    printf "%${width}s\n" | tr ' ' '='
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
    printf "%${width}s\n" | tr ' ' '='
    echo
}

# Progress bar function
show_progress() {
    local duration=$1
    local width=50
    local progress=0
    local step=$(( 100 / $duration ))
    
    while [ $progress -le 100 ]; do
        local completed=$(( $width * $progress / 100 ))
        local remaining=$(( $width - $completed ))
        printf "\rProgress: [${GREEN}%${completed}s${NC}%${remaining}s] ${progress}%%" "" ""
        progress=$(( progress + step ))
        sleep 1
    done
    echo
}
