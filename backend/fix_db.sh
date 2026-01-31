#!/bin/bash
set -e
echo "Fixing Database..."
export DEBIAN_FRONTEND=noninteractive
systemctl stop mysql mariadb || true
apt-get purge -y mysql* mariadb* || true
rm -rf /var/lib/mysql
rm -rf /etc/mysql
apt-get autoremove -y
apt-get install -y mariadb-server

systemctl start mariadb

echo "Setting up DB..."
mysql -e "CREATE DATABASE IF NOT EXISTS BaiKiemTraDb;"
# On fresh MariaDB install, root has no password (unix_socket).
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'Pubg1751993'; FLUSH PRIVILEGES;"

echo "Restarting App..."
systemctl restart pickleball
sleep 5
systemctl status pickleball --no-pager
