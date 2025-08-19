#!/bin/sh

NEW_C=$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 2 | head -n 1)
NEW_ST=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
NEW_L=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
NEW_O=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 3 | head -n 1)
NEW_CN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
mkdir -p /etc/ssl/private/
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -sha256 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem -subj ""/C=$NEW_C/ST=$NEW_ST/L=$NEW_L/O=$NEW_O/CN=$NEW_CN""
