#!/bin/bash

install_certbot() {
    if ! command -v certbot &> /dev/null; then
        echo "Installing Certbot..."
        sudo apt update
        sudo apt install -y certbot
    else
        echo "Certbot is already installed."
    fi
}

get_input() {
    read -p "Enter your domain (e.g., example.com): " domain
    read -p "Enter your email address: " email
}

get_panel_type() {
    echo "Select panel type:"
    echo "1) Marzban (Main Panel)"
    echo "2) Marzneshin (Resident Panel)"
    read -p "Your choice (1 or 2): " panel_choice

    case $panel_choice in
        1) panel_type="marzban" ;;
        2) 
            panel_type="marzneshin"
            echo "Select server type:"
            echo "1) Master Server"
            echo "2) Node Server"
            read -p "Your choice (1 or 2): " node_choice
            
            case $node_choice in
                1) node_type="master" ;;
                2) node_type="node" ;;
                *) 
                    echo "Invalid selection!"
                    exit 1
                    ;;
            esac
            ;;
        *) 
            echo "Invalid selection!"
            exit 1
            ;;
    esac
}

manage_certificate() {
    local domain=$1
    local email=$2

    if sudo certbot certificates | grep -q "$domain"; then
        echo "Certificate for $domain exists. Renewing..."
        sudo certbot renew --force-renewal --cert-name "$domain"
    else
        echo "Issuing new certificate for $domain..."
        sudo certbot certonly --standalone --agree-tos --non-interactive --email "$email" -d "$domain"
    fi
}

create_directory_if_not_exists() {
    local dir_path=$1
    if [ ! -d "$dir_path" ]; then
        echo "Creating directory: $dir_path"
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

    echo "Certificate files copied from:"
    echo "Source: $cert_path"
    echo "Destination: $target_path"
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

    echo -e "\nCertificate Details:"
    echo "----------------------------------------"
    echo "Domain: $domain"
    echo "Certificate Path: $target_path/fullchain.pem"
    echo "Private Key Path: $target_path/privkey.pem"
    echo "----------------------------------------"
}

# Main execution
install_certbot
get_panel_type
get_input
manage_certificate "$domain" "$email"
copy_certificates "$domain"
display_certificates "$domain"

echo "Operation completed successfully!"