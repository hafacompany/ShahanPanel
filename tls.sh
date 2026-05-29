#!/bin/bash
# =============================================
# ShaHaN SSH_TLS Installer - Steps Only
# Author: HamedAp
# =============================================

set -e

# Typing Effect Function
printshahan() {
    text="$1"
    delay="$2"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}

clear
echo ""
printshahan "ShaHaN SSH_TLS Installation :) By HamedAp" 0.05
echo ""
echo ""

# Step 1
echo "Step 1: Getting required information..."
read -rp "Please enter the pointed domain / sub-domain name: " domain
read -rp "Please enter SSH PORT: " sshport

# Step 2
echo "Step 2: Configuring Apache SSL VirtualHost..."
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

# Step 3
echo "Step 3: Configuring Apache Ports..."
cat > /etc/apache2/ports.conf <<EOF
Listen 0.0.0.0:80
<IfModule ssl_module>
        Listen 0.0.0.0:8443
</IfModule>
<IfModule mod_gnutls.c>
        Listen 0.0.0.0:8443
</IfModule>
EOF

# Step 4
echo "Step 4: Restarting Apache..."
sudo systemctl restart apache2 >/dev/null 2>&1

# Step 5
echo "Step 5: Installing stunnel4 and sslh..."
sudo apt install stunnel4 sslh -y >/dev/null 2>&1

# Step 6
echo "Step 6: Configuring Stunnel..."
cat > /etc/stunnel/stunnel.conf <<EOF
pid = /var/run/stunnel.pid
cert = /etc/apache2/ssl/${domain}.crt
key = /etc/apache2/ssl/${domain}.key
[ssh]
accept = 0.0.0.0:443
connect = localhost:2000
EOF

# Step 7
echo "Step 7: Enabling Stunnel..."
if ! grep -q '^ENABLED=1' /etc/default/stunnel4; then
    echo "ENABLED=1" >> /etc/default/stunnel4
fi

# Step 8
echo "Step 8: Starting Stunnel..."
service stunnel4 start >/dev/null 2>&1

# Step 9
echo "Step 9: Configuring SSLH..."
cat > /etc/default/sslh <<EOF
RUN=yes
DAEMON=/usr/sbin/sslh
DAEMON_OPTS="--user sslh --listen 0.0.0.0:2000 --ssh 127.0.0.1:${sshport} --ssl 127.0.0.1:8443 --http 127.0.0.1:80 --pidfile /var/run/sslh/sslh.pid"
EOF

# Step 10
echo "Step 10: Restarting SSLH..."
sudo systemctl restart sslh >/dev/null 2>&1

clear
echo ""
printshahan "✅ Installation Completed Successfully!" 0.05
echo ""
echo "You can now connect using your domain on port 443."
