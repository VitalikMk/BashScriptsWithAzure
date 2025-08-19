#!/bin/bash

if [ -f "/root/creds_for_glpi" ]; then
	echo "file exists /root/creds_for_glpi"
	exit 1
fi

if [ -f "/root/root_password" ]; then
	echo "file exists /root/root_password"
	exit 1
fi



passwordRoot=$(tr -dc 'A-Za-z0-9!$#%^&*();:' </dev/urandom | head -c 15)
passGLPI=$(tr -dc 'A-Za-z0-9!$#%^&*();:' </dev/urandom | head -c 15)

sudo systemctl stop mariadb
sleep 5
sudo systemctl set-environment MYSQLD_OPTS="--skip-grant-tables --skip-networking"
sudo systemctl start mariadb
sudo systemctl status mariadb
sleep 10
echo ""

#Setup root user
sleep 5
echo "START MYSQL SAFE"
sudo mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY '$passwordRoot'; FLUSH PRIVILEGES;"
echo ""
sleep 5
echo "Root password db: $passwordRoot" | sudo tee "/root/root_password" > /dev/null

sudo systemctl unset-environment MYSQLD_OPTS
sudo systemctl restart mariadb


#Setup glpi user and db

dbNameToCreate="glpi"
userNameToCreate="glpi"

sudo mysql -u root  --password="$passwordRoot" -e "CREATE DATABASE $dbNameToCreate;"
sudo mysql -u root  --password="$passwordRoot" -e "CREATE USER '$userNameToCreate'@'localhost' IDENTIFIED BY '$passGLPI';"
sudo mysql -u root  --password="$passwordRoot" -e "GRANT ALL PRIVILEGES ON $dbNameToCreate.* TO '$userNameToCreate'@'localhost';"
sudo mysql -u root  --password="$passwordRoot" -e "FLUSH PRIVILEGES;"
sudo mysql -u root  --password="$passwordRoot" -e "GRANT SELECT ON mysql.time_zone_name TO '$userNameToCreate'@'localhost'"

{
    echo "SQL server: localhost"
    echo "Database name: glpi"
    echo "Username: glpi"
    echo "Password: $passGLPI"
} | sudo tee "/root/creds_for_glpi" > /dev/null




sudo systemctl enable mariadb.service


