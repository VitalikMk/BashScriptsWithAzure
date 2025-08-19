#!/bin/bash
echo "CONF HOST"
echo "
<VirtualHost *:80>
		    ServerName yourglpi.yourdomain.com
		    DocumentRoot /var/www/html/glpi/public
		    <Directory /var/www/html/glpi/public>
		        Require all granted
		        RewriteEngine On
		        RewriteCond %{HTTP:Authorization} ^(.+)$
		        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
		        RewriteCond %{REQUEST_FILENAME} !-f
		        RewriteRule ^(.*)$ index.php [QSA,L]
		    </Directory>
		</VirtualHost>
 "| sudo tee /etc/apache2/sites-available/glpi.conf > /dev/null



versionPhp=$(ls /etc/php/)
sudo sed -i 's/upload_max_filesize\s*=.*/upload_max_filesize = 20M/' /etc/php/$versionPhp/apache2/php.ini
sudo sed -i 's/post_max_size\s*=.*/post_max_size = 20M/' /etc/php/$versionPhp/apache2/php.ini
sudo sed -i 's/max_execution_time\s*=.*/max_execution_time = 60/' /etc/php/$versionPhp/apache2/php.ini
sudo sed -i 's/max_input_vars\s*=.*/max_input_vars = 5000/' /etc/php/$versionPhp/apache2/php.ini
sudo sed -i 's/memory_limit\s*=.*/memory_limit = 256M/' /etc/php/$versionPhp/apache2/php.ini
sudo sed -i 's/session.cookie_httponly\s*=.*/session.cookie_httponly = On/' /etc/php/$versionPhp/apache2/php.ini

sudo a2enmod rewrite
sudo a2ensite glpi.conf
sudo a2dissite 000-default.conf
