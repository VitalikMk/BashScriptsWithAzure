#!/bin/bash
echo "CONF FILE DIR"
sudo chown root:root /srv/www/htdocs/glpi/ -R
sudo chown wwwrun:www /etc/glpi -R
sudo chown wwwrun:www /var/lib/glpi -R
sudo chown wwwrun:www /var/log/glpi -R
sudo chown wwwrun:www /srv/www/htdocs/glpi/marketplace -Rf
sudo find /srv/www/htdocs/glpi/ -type f -exec chmod 0644 {} \;
sudo find /srv/www/htdocs/glpi/ -type d -exec chmod 0755 {} \;
sudo find /etc/glpi -type f -exec chmod 0644 {} \;
sudo find /etc/glpi -type d -exec chmod 0755 {} \;
sudo find /var/lib/glpi -type f -exec chmod 0644 {} \;
sudo find /var/lib/glpi -type d -exec chmod 0755 {} \;
sudo find /var/log/glpi -type f -exec chmod 0644 {} \;
sudo find /var/log/glpi -type d -exec chmod 0755 {} \;
