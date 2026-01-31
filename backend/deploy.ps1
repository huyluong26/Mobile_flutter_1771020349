$ErrorActionPreference = "Stop"

$VPS_IP = "103.77.173.6"
$VPS_USER = "root"

Write-Host "--- Starting Deployment to $VPS_IP ---"

# 1. Zip the published files
Write-Host "Compressing files..."
if (Test-Path "publish.zip") { Remove-Item "publish.zip" }
Compress-Archive -Path "publish\*" -DestinationPath "publish.zip"

# 2. VPS Setup Script (Contains ALL logic to avoid SSH string issues)
$setupScriptContent = @"
#!/bin/bash
set -e

echo "Updating system..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y nginx mariadb-server unzip

echo "Configuring Database..."
systemctl start mariadb
mysql -e "CREATE DATABASE IF NOT EXISTS BaiKiemTraDb;"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Pubg1751993'; FLUSH PRIVILEGES;" || echo "Root password might already be set."

echo "Preparing App Directory..."
rm -rf /var/www/pickleball
mkdir -p /var/www/pickleball

echo "Unzipping application..."
unzip -o /root/publish.zip -d /var/www/pickleball
chmod +x /var/www/pickleball/backend

echo "Creating Systemd Service..."
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

echo "Applying Service..."
systemctl daemon-reload
systemctl enable pickleball
systemctl restart pickleball

echo "Configuring Nginx..."
cat > /etc/nginx/sites-available/default <<EOL
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass         http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade \$http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto \$scheme;
    }
}
EOL

echo "Reloading Nginx..."
nginx -t
systemctl reload nginx

echo "--- DEPLOYMENT COMPLETE ---"
"@

# Normalize to LF (Linux line endings)
$setupScriptContent = $setupScriptContent -replace "`r`n", "`n"

# Write file using .NET API to ensure correct encoding and no BOM
$startPath = Get-Location
$filePath = Join-Path $startPath "setup_vps.sh"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($filePath, $setupScriptContent, $utf8NoBom)

# 3. Copy files to VPS
Write-Host "Copying files to VPS... (Password: manhduy1107@ )"
scp setup_vps.sh publish.zip ${VPS_USER}@${VPS_IP}:/root/

# 4. Execute Setup
Write-Host "Executing setup on VPS..."
# Use sed to remove any stubborn carriage returns that might have survived transfer
$cmd = "sed -i 's/\r$//' setup_vps.sh && chmod +x setup_vps.sh && ./setup_vps.sh"
ssh ${VPS_USER}@${VPS_IP} $cmd

Write-Host "Done! Backend should be live at http://${VPS_IP}"
