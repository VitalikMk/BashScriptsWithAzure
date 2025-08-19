#!/bin/bash

passwordRoot=$(tr -dc 'A-Za-z0-9!$#%^&*();:' </dev/urandom | head -c 15)
passGLPI=$(tr -dc 'A-Za-z0-9!$#%^&*();:' </dev/urandom | head -c 15)

{
    echo "SQL server: localhost"
    echo "Database name: glpi"
    echo "Username: glpi"
    echo "Password: $passGLPI"
} | sudo tee "/root/creds_for_glpi" > /dev/null

sudo systemctl status mysql.service
sudo systemctl stop mysql.service

sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo chmod 755 /var/run/mysqld

sudo systemctl stop mysql
sudo pkill -f mysqld

sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo chmod 755 /var/run/mysqld


sleep 5
sudo mysqld_safe --skip-grant-tables --skip-networking --socket=/var/run/mysqld/mysqld.sock &
echo ""
sleep 10
echo ""

sleep 5
echo "START MYSQL SAFE"
sudo mysql -u root -e "USE mysql; UPDATE user SET password='' WHERE User='root'; FLUSH PRIVILEGES;"

sleep 5
sudo pkill mysqld
echo ""
sleep 5
echo ""
sudo systemctl start mysql.service

sudo mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$passwordRoot'; FLUSH PRIVILEGES;"

sudo mysql -u root  --password="$passwordRoot" -e "CREATE DATABASE glpi;"
sudo mysql -u root  --password="$passwordRoot" -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY '$passGLPI';"
sudo mysql -u root  --password="$passwordRoot" -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
sudo mysql -u root  --password="$passwordRoot" -e "FLUSH PRIVILEGES;"



