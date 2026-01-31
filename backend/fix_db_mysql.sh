#!/bin/bash
set -e
echo "Switching to MySQL Server..."
export DEBIAN_FRONTEND=noninteractive
systemctl stop mariadb mysql || true
apt-get purge -y mariadb* mysql* || true
rm -rf /var/lib/mysql
rm -rf /etc/mysql
apt-get autoremove -y
# Install MySQL 8
apt-get install -y mysql-server

systemctl start mysql

echo "Setting up DB..."
mysql -e "CREATE DATABASE IF NOT EXISTS BaiKiemTraDb;"
# Allow root login with password
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Pubg1751993'; FLUSH PRIVILEGES;"

echo "Restarting App..."
systemctl restart pickleball
sleep 5
systemctl status pickleball --no-pager
