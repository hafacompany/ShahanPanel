#!/bin/bash
# =============================================
# ShaHaN SSH_TLS Installer - Professional Edition
# Author: HamedAp
# Version: 2.0
# =============================================

set -e

# 🎨 Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ✨ Typing Effect Function
printshahan() {
    text="$1"
    delay="$2"
    color="$3"
    echo -ne "${color}"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo -e "${NC}"
}

# 📦 Header Function
show_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║     🔐 ShaHaN SSH_TLS Installer - Professional Edition      ║"
    echo "║                    ✨ Author: HamedAp ✨                      ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# ✅ Success Message
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# ⚠️ Warning Message
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 🔄 Progress Message
show_progress() {
    echo -e "${BLUE}🔄 $1${NC}"
}

# 📋 Info Message
show_info() {
    echo -e "${MAGENTA}📋 $1${NC}"
}

# 🚀 Step Header
show_step() {
    echo ""
    echo -e "${CYAN}${BOLD}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}${BOLD}│  📌 Step $1${NC}"
    echo -e "${CYAN}${BOLD}└──────────────────────────────────────────────────────────┘${NC}"
}

# =============================================
# Main Script Starts Here
# =============================================

show_header

# 🌟 Welcome Message
printshahan "✨ Welcome! Let's set up your SSH_TLS tunnel securely... ✨" 0.03 "${GREEN}${BOLD}"
echo ""
sleep 1

# =============================================
# Step 1 - Information Gathering
# =============================================
show_step "1/10 - Gathering Required Information"
echo ""
show_info "Please provide the following details for configuration:"
echo ""

read -rp "   🌐 Enter your pointed domain/sub-domain name: " domain
while [[ -z "$domain" ]]; do
    show_warning "Domain cannot be empty!"
    read -rp "   🌐 Enter your pointed domain/sub-domain name: " domain
done

read -rp "   🔌 Enter your desired SSH port (e.g., 22, 2222): " sshport
while [[ -z "$sshport" ]]; do
    show_warning "SSH port cannot be empty!"
    read -rp "   🔌 Enter your desired SSH port: " sshport
done

show_success "Information saved: Domain → $domain , SSH Port → $sshport"
sleep 1

# =============================================
# Step 2 - Apache SSL VirtualHost Configuration
# =============================================
show_step "2/10 - Configuring Apache SSL VirtualHost"
show_progress "Creating SSL VirtualHost configuration file..."

cat > /etc/apache2/sites-available/default-ssl.conf <<EOF
<IfModule mod_ssl.c>
        <VirtualHost _default_:8443>
                ServerAdmin ShaHaN@${domain}
                ServerName ${domain}
                DocumentRoot /var/www/html
                ErrorLog /error.log
                CustomLog /access.log combined
                SSLEngine on
                SSLCertificateFile      /etc/apache2/ssl/${domain}.crt
                SSLCertificateKeyFile /etc/apache2/ssl/${domain}.key
                <FilesMatch '\.(cgi|shtml|phtml|php)$'>
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
        </VirtualHost>
</IfModule>
EOF

show_success "Apache SSL VirtualHost configured at /etc/apache2/sites-available/default-ssl.conf"
sleep 1

# =============================================
# Step 3 - Apache Ports Configuration
# =============================================
show_step "3/10 - Configuring Apache Ports"
show_progress "Setting up Apache to listen on ports 80 and 8443..."

cat > /etc/apache2/ports.conf <<EOF
Listen 0.0.0.0:80
<IfModule ssl_module>
        Listen 0.0.0.0:8443
</IfModule>
<IfModule mod_gnutls.c>
        Listen 0.0.0.0:8443
</IfModule>
EOF

show_success "Apache ports configured (HTTP:80 , HTTPS:8443)"
sleep 1

# =============================================
# Step 4 - Restart Apache
# =============================================
show_step "4/10 - Restarting Apache Service"
show_progress "Applying new Apache configuration..."

if systemctl restart apache2 >/dev/null 2>&1; then
    show_success "Apache restarted successfully"
else
    show_warning "Apache restart encountered issues, continuing anyway..."
fi
sleep 1

# =============================================
# Step 5 - Installing Required Packages
# =============================================
show_step "5/10 - Installing Required Packages (stunnel4 & sslh)"
show_progress "Updating package list and installing dependencies..."
show_info "This may take a moment depending on your internet speed..."

sudo apt update -qq >/dev/null 2>&1
sudo DEBIAN_FRONTEND=noninteractive apt install stunnel4 sslh -y

show_success "Packages installed: stunnel4 , sslh"
sleep 1

# =============================================
# Step 6 - Stunnel Configuration
# =============================================
show_step "6/10 - Configuring Stunnel (SSL Tunnel)"
show_progress "Creating Stunnel configuration for port 443..."

cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel.pid
cert = /etc/apache2/ssl/${domain}.crt
key = /etc/apache2/ssl/${domain}.key

[ssh]
accept = 0.0.0.0:443
connect = localhost:2000
EOF

show_success "Stunnel configured to listen on port 443 and forward to port 2000"
sleep 1

# =============================================
# Step 7 - Enabling Stunnel
# =============================================
show_step "7/10 - Enabling Stunnel Service"
show_progress "Configuring Stunnel to start on boot..."

if ! grep -q '^ENABLED=1' /etc/default/stunnel4; then
    echo "ENABLED=1" >> /etc/default/stunnel4
    show_success "Stunnel enabled"
else
    show_info "Stunnel already enabled"
fi
sleep 1

# =============================================
# Step 8 - Starting Stunnel
# =============================================
show_step "8/10 - Starting Stunnel Service"
show_progress "Launching Stunnel daemon..."

if service stunnel4 start >/dev/null 2>&1; then
    show_success "Stunnel started successfully"
else
    show_warning "Stunnel may already be running, continuing..."
fi
sleep 1

# =============================================
# Step 9 - SSLH Configuration
# =============================================
show_step "9/10 - Configuring SSLH (SSL Multiplexer)"
show_progress "Setting up SSLH to handle SSH and HTTPS traffic..."

cat > /etc/default/sslh <<EOF
RUN=yes
DAEMON=/usr/sbin/sslh
DAEMON_OPTS="--user sslh --listen 0.0.0.0:2000 --ssh 127.0.0.1:${sshport} --ssl 127.0.0.1:8443 --http 127.0.0.1:80 --pidfile /var/run/sslh/sslh.pid"
EOF

show_success "SSLH configured to multiplex SSH (port $sshport) and HTTPS (port 8443)"
sleep 1

# =============================================
# Step 10 - Restart SSLH
# =============================================
show_step "10/10 - Finalizing: Restarting SSLH Service"
show_progress "Applying SSLH configuration..."

if systemctl restart sslh >/dev/null 2>&1; then
    show_success "SSLH restarted successfully"
else
    show_warning "SSLH restart issue, checking service status..."
    systemctl status sslh --no-pager
fi
sleep 1

# =============================================
# Final Summary
# =============================================
clear
show_header
echo ""
printshahan "🎉 Installation Completed Successfully! 🎉" 0.05 "${GREEN}${BOLD}"
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║                    🔧 CONNECTION DETAILS                     ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "   🌍 ${BOLD}Domain:${NC}      ${GREEN}$domain${NC}"
echo -e "   🔌 ${BOLD}SSH Port:${NC}    ${GREEN}$sshport${NC}"
echo -e "   🚪 ${BOLD}Gateway:${NC}     ${GREEN}443 (TLS Tunnel)${NC}"
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}${BOLD}║                    📖 CONNECTION GUIDE                       ║${NC}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "   ${YELLOW}▶  SSH Command:${NC}     ssh -p $sshport user@$domain"
echo -e "   ${YELLOW}▶  Tunnel Port:${NC}     Connect to port 443 with SSL/TLS"
echo -e "   ${YELLOW}▶  Multiplexer:${NC}     SSLH handles SSH + HTTPS on same port"
echo ""
echo -e "${GREEN}✅ Your SSH_TLS tunnel is ready to use!${NC}"
echo ""
echo -e "${BLUE}💡 Tip: Make sure your SSL certificates are placed in:${NC}"
echo -e "   /etc/apache2/ssl/${domain}.crt"
echo -e "   /etc/apache2/ssl/${domain}.key"
echo ""
