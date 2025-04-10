#!/bin/bash

# Auto-installer for Marzban SSL Certificate Renewal

# Configuration
RENEW_SCRIPT="/etc/marzban-cert-renewer.sh"
CRON_SCHEDULE="0 4 * * 6"  # Every Saturday at 4 AM
CRON_JOB="$CRON_SCHEDULE $RENEW_SCRIPT"

# Create the renewal script
cat > "$RENEW_SCRIPT" << 'EOL'
#!/bin/bash

# Marzban SSL Certificate Auto-Renewal Script

CERTS_DIR="/var/lib/marzban/certs"

# Renew all certificates
echo "Starting SSL certificate renewal..."
certbot renew --quiet --non-interactive --agree-tos

# Update certificates in Marzban
for domain in $(ls /etc/letsencrypt/live/ 2>/dev/null); do
    if [ "$domain" != "README" ]; then
        echo "Updating certificates for $domain"
        mkdir -p "$CERTS_DIR/$domain"
        cp -f "/etc/letsencrypt/live/$domain/fullchain.pem" "$CERTS_DIR/$domain/fullchain.pem"
        cp -f "/etc/letsencrypt/live/$domain/privkey.pem" "$CERTS_DIR/$domain/privkey.pem"
        chown marzban:marzban "$CERTS_DIR/$domain"/*
        chmod 600 "$CERTS_DIR/$domain/privkey.pem"
        chmod 644 "$CERTS_DIR/$domain/fullchain.pem"
    fi
done

# Restart Marzban service
echo "Restarting Marzban service..."
marzban restart >/dev/null 2>&1

echo "Certificate renewal process completed at $(date)"
EOL

# Set execution permissions
chmod +x "$RENEW_SCRIPT"

# Add to crontab
echo "Configuring scheduled job..."
(crontab -l 2>/dev/null | grep -v "$RENEW_SCRIPT"; echo "$CRON_JOB") | crontab -

# Verification
echo ""
echo "=== Installation Summary ==="
echo "1. Renewal script installed to: $RENEW_SCRIPT"
echo "2. Scheduled to run: $CRON_SCHEDULE (Every Saturday at 4 AM)"
echo "3. To verify cron job: crontab -l"
echo "4. To manually run: $RENEW_SCRIPT"
echo ""
echo "Note: Ensure certbot is installed and certificates were initially issued"
echo "For first-time setup, run: certbot certonly --standalone -d yourdomain.com"