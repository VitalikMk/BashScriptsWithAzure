#!/bin/bash


sudo systemctl restart apache2
echo "CONF HOST"
sudo tee /etc/apache2/vhosts.d/glpi.conf > /dev/null << 'EOF'
<VirtualHost *:80>
    ServerName yourglpi.yourdomain.com
    DocumentRoot /srv/www/htdocs/glpi/public

    <Directory /srv/www/htdocs/glpi>
        Options -Indexes
        AllowOverride None
        Require all denied
    </Directory>

    <Directory /srv/www/htdocs/glpi/public>
       Options +FollowSymLinks -Indexes
       AllowOverride All
       Require all granted
       RewriteEngine On
       RewriteCond %{HTTP:Authorization} ^(.+)$
       RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
       RewriteCond %{REQUEST_FILENAME} !-f
       RewriteRule ^(.*)$ index.php [QSA,L]
   </Directory>

    ErrorLog /var/log/apache2/glpi_error.log
    CustomLog /var/log/apache2/glpi_access.log combined
</VirtualHost>
EOF

sudo sed -i 's/upload_max_filesize\s*=.*/upload_max_filesize = 20M/' /etc/php8/apache2/php.ini
sudo sed -i 's/post_max_size\s*=.*/post_max_size = 20M/' /etc/php8/apache2/php.ini
sudo sed -i 's/max_execution_time\s*=.*/max_execution_time = 60/' /etc/php8/apache2/php.ini
sudo sed -i 's/max_input_vars\s*=.*/max_input_vars = 5000/' /etc/php8/apache2/php.ini
sudo sed -i 's/memory_limit\s*=.*/memory_limit = 256M/' /etc/php8/apache2/php.ini
sudo sed -i 's/session.cookie_httponly\s*=.*/session.cookie_httponly = On/' /etc/php8/apache2/php.ini
sudo sed -i 's/;extension=curl\s*=.*/extension=curl/' /etc/php8/apache2/php.ini
sudo sed -i 's/;extension=mbstring\s*=.*/extension=mbstring/' /etc/php8/apache2/php.ini

sudo a2enmod rewrite

sudo systemctl restart apache2
