#!/bin/bash
echo "CONF DILE DIR"
sudo chown root:root /var/www/html/glpi/ -R
sudo chown apache:apache /etc/glpi -R
sudo chown apache:apache /var/lib/glpi -R
sudo chown apache:apache /var/log/glpi -R
sudo chown apache:apache /var/www/html/glpi/marketplace -Rf
sudo find /var/www/html/glpi/ -type f -exec chmod 0644 {} \;
sudo find /var/www/html/glpi/ -type d -exec chmod 0755 {} \;
sudo find /etc/glpi -type f -exec chmod 0644 {} \;
sudo find /etc/glpi -type d -exec chmod 0755 {} \;
sudo find /var/lib/glpi -type f -exec chmod 0644 {} \;
sudo find /var/lib/glpi -type d -exec chmod 0755 {} \;
sudo find /var/log/glpi -type f -exec chmod 0644 {} \;
sudo find /var/log/glpi -type d -exec chmod 0755 {} \;


sudo chown apache:apache /var/www/html/glpi/marketplace
sudo chmod 775 /var/www/html/glpi/marketplace

