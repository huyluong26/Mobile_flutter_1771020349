#!/bin/bash
set -e

echo "Updating system..."
export DEBIAN_FRONTEND=noninteractive
# Stop old services just in case
systemctl stop mariadb mysql || true
systemctl stop pickleball || true

apt-get update -qq
apt-get install -y nginx unzip

echo "Preparing App Directory..."
rm -rf /var/www/pickleball
mkdir -p /var/www/pickleball

echo "Unzipping application..."
unzip -o /root/publish.zip -d /var/www/pickleball
chmod +x /var/www/pickleball/backend

# Create DB file permissions (SQLite)
touch /var/www/pickleball/pickleball.db
chmod 666 /var/www/pickleball/pickleball.db

echo "Creating Systemd Service..."
cat > /etc/systemd/system/pickleball.service <<EOL
[Unit]
Description=Pickleball Backend API
After=network.target

[Service]
WorkingDirectory=/var/www/pickleball
ExecStart=/var/www/pickleball/backend
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=pickleball-backend
User=root
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false
Environment=ASPNETCORE_URLS=http://localhost:5000

[Install]
WantedBy=multi-user.target
EOL

echo "Applying Service..."
systemctl daemon-reload
systemctl enable pickleball
systemctl restart pickleball
sleep 5
systemctl status pickleball --no-pager

echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/default <<EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass         http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host \System.Management.Automation.Internal.Host.InternalHost;
        proxy_cache_bypass \;
        proxy_set_header   X-Forwarded-For \;
        proxy_set_header   X-Forwarded-Proto \;
    }
}
EOL

echo "Reloading Nginx..."
nginx -t
systemctl reload nginx

echo "--- DEPLOYMENT COMPLETE ---"