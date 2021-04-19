#!/bin/bash

sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx Full'
sudo apt install mysql-server
sudo mysql_secure_installation
sudo apt install php-fpm php-mysql php-curl php-mbstring php-imagick php-zip
