#!/bin/bash
set -e
rm -rf /var/www/pickleball*
mkdir -p /var/www/pickleball
unzip -o /root/publish.zip -d /var/www/pickleball
chmod +x /var/www/pickleball/backend

cat > /etc/systemd/system/pickleball.service <<EOL
[Unit]
Description=Pickleball Backend API
After=network.target mysql.service

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

# Sanitize service file
sed -i 's/\r//g' /etc/systemd/system/pickleball.service

systemctl daemon-reload
systemctl enable pickleball
systemctl restart pickleball
systemctl status pickleball --no-pager
nginx -t
systemctl reload nginx
