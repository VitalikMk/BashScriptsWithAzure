#!/bin/bash
echo "CONF HOST"
sudo tee /etc/httpd/conf.d/glpi.conf > /dev/null << 'EOF'
<VirtualHost *:80>

    <Directory /var/www/html/glpi>
        Options -Indexes
        AllowOverride None
        Require all denied
    </Directory>
    
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

    ErrorLog /var/log/httpd/glpi_error.log
    CustomLog /var/log/httpd/glpi_access.log combined
</VirtualHost>
EOF


sudo sed -i 's/upload_max_filesize\s*=.*/upload_max_filesize = 20M/' /etc/php.ini
sudo sed -i 's/post_max_size\s*=.*/post_max_size = 20M/' /etc/php.ini
sudo sed -i 's/max_execution_time\s*=.*/max_execution_time = 60/' /etc/php.ini
sudo sed -i 's/max_input_vars\s*=.*/max_input_vars = 5000/' /etc/php.ini
sudo sed -i 's/memory_limit\s*=.*/memory_limit = 256M/' /etc/php.ini
sudo sed -i 's/session.cookie_httponly\s*=.*/session.cookie_httponly = On/' /etc/php.ini
sudo sed -i 's/;extension=curl\s*=.*/extension=curl/' /etc/php.ini
sudo sed -i 's/;extension=mbstring\s*=.*/extension=mbstring/' /etc/php.ini

