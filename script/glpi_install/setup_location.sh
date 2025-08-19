#!/bin/bash

timeZone=$(timedatectl | grep "Time zone:" | awk '{print $3}')
versionPhp=$(ls /etc/php/)
sudo sed -i "s|;date.timezone\s*=.*|date.timezone = $timeZone|" /etc/php/$versionPhp/apache2/php.ini
