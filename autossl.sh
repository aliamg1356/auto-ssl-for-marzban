#!/bin/bash

# Color definitions
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

display_logo() {
    echo -e "${YELLOW}
    ██╗   ██╗████████╗██╗   ██╗███╗   ██╗███╗   ██╗███████╗██╗     
    ██║   ██║╚══██╔══╝██║   ██║████╗  ██║████╗  ██║██╔════╝██║     
    ██║   ██║   ██║   ██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██║     
    ██║   ██║   ██║   ██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██║     
    ╚██████╔╝   ██║   ╚██████╔╝██║ ╚████║██║ ╚████║███████╗███████╗
     ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚══════╝
                                                                  
             ushkayanet ssl for marzban/marzneshin console
    ${NC}"
}

install_certbot() {
    if ! command -v certbot &> /dev/null; then
        echo -e "${YELLOW}[~] Installing Certbot...${NC}"
        sudo apt update > /dev/null 2>&1
        sudo apt install -y certbot > /dev/null 2>&1
        echo -e "${GREEN}[✓] Certbot installed successfully${NC}"
    else
        echo -e "${GREEN}[✓] Certbot is already installed${NC}"
    fi
}

get_input() {
    echo -e "\n${BLUE}== Domain Information ==${NC}"
    read -p "$(echo -e ${YELLOW}'Enter your domain (e.g., example.com): '${NC})" domain
    read -p "$(echo -e ${YELLOW}'Enter your email address: '${NC})" email
}

get_panel_type() {
    echo -e "\n${BLUE}== Panel Selection ==${NC}"
    echo -e "  ${CYAN}1) Marzban (Main Panel)${NC}"
    echo -e "  ${CYAN}2) Marzneshin (Resident Panel)${NC}"
    read -p "$(echo -e ${YELLOW}'Your choice [1-2]: '${NC})" panel_choice

    case $panel_choice in
        1) 
            panel_type="marzban"
            echo -e "${GREEN}  Selected: Marzban Main Panel${NC}"
            ;;
        2) 
            panel_type="marzneshin"
            echo -e "\n${BLUE}== Server Type ==${NC}"
            echo -e "  ${CYAN}1) Master Server${NC}"
            echo -e "  ${CYAN}2) Node Server${NC}"
            read -p "$(echo -e ${YELLOW}'Your choice [1-2]: '${NC})" node_choice
            
            case $node_choice in
                1) 
                    node_type="master"
                    echo -e "${GREEN}  Selected: Marzneshin Master${NC}"
                    ;;
                2) 
                    node_type="node"
                    echo -e "${GREEN}  Selected: Marzneshin Node${NC}"
                    ;;
                *) 
                    echo -e "${RED}[✗] Invalid selection!${NC}"
                    exit 1
                    ;;
            esac
            ;;
        *) 
            echo -e "${RED}[✗] Invalid selection!${NC}"
            exit 1
            ;;
    esac
}

manage_certificate() {
    local domain=$1
    local email=$2

    echo -e "\n${BLUE}== Certificate Operation ==${NC}"
    if sudo certbot certificates | grep -q "$domain"; then
        echo -e "${YELLOW}[~] Renewing existing certificate for $domain...${NC}"
        sudo certbot renew --force-renewal --cert-name "$domain"
    else
        echo -e "${YELLOW}[~] Issuing new certificate for $domain...${NC}"
        sudo certbot certonly --standalone --agree-tos --non-interactive --email "$email" -d "$domain"
    fi
}

create_directory_if_not_exists() {
    local dir_path=$1
    if [ ! -d "$dir_path" ]; then
        echo -e "${YELLOW}[~] Creating directory: $dir_path${NC}"
        sudo mkdir -p "$dir_path"
        sudo chmod -R 755 "$dir_path"
    fi
}

copy_certificates() {
    local domain=$1
    local cert_path="/etc/letsencrypt/live/$domain"
    local target_path=""

    case "$panel_type" in
        "marzban")
            target_path="/var/lib/marzban/certs/$domain"
            create_directory_if_not_exists "/var/lib/marzban"
            create_directory_if_not_exists "/var/lib/marzban/certs"
            ;;
        "marzneshin")
            case "$node_type" in
                "master")
                    target_path="/var/lib/marzneshin/certs/$domain"
                    create_directory_if_not_exists "/var/lib/marzneshin"
                    create_directory_if_not_exists "/var/lib/marzneshin/certs"
                    ;;
                "node")
                    target_path="/var/lib/marznode/certs/$domain"
                    create_directory_if_not_exists "/var/lib/marznode"
                    create_directory_if_not_exists "/var/lib/marznode/certs"
                    ;;
            esac
            ;;
    esac

    create_directory_if_not_exists "$target_path"

    sudo rm -f "$target_path/fullchain.pem" "$target_path/privkey.pem"
    sudo cp "$cert_path/fullchain.pem" "$target_path/"
    sudo cp "$cert_path/privkey.pem" "$target_path/"

    echo -e "\n${GREEN}[✓] Certificate files copied:${NC}"
    echo -e "  ${CYAN}From: $cert_path${NC}"
    echo -e "  ${CYAN}To:   $target_path${NC}"
}

display_certificates() {
    local domain=$1
    local target_path=""

    case "$panel_type" in
        "marzban") target_path="/var/lib/marzban/certs/$domain" ;;
        "marzneshin")
            case "$node_type" in
                "master") target_path="/var/lib/marzneshin/certs/$domain" ;;
                "node") target_path="/var/lib/marznode/certs/$domain" ;;
            esac
            ;;
    esac

    echo -e "\n${BLUE}== Certificate Details ==${NC}"
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║ ${CYAN}Domain:    $domain${NC}"
    echo -e "${GREEN}║ ${CYAN}Cert Path: $target_path/fullchain.pem${NC}"
    echo -e "${GREEN}║ ${CYAN}Key Path:  $target_path/privkey.pem${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
}

# Main execution
clear
display_logo
install_certbot
get_panel_type
get_input
manage_certificate "$domain" "$email"
copy_certificates "$domain"
display_certificates "$domain"

echo -e "\n${GREEN}[✓] Operation completed successfully!${NC}"
