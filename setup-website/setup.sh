#!/bin/bash

. ../setup-user/setup.sh

domain=$1
user=$2
root="/home/$user/$domain/public"
block="/etc/nginx/sites-available/$domain"

# Create the Document Root directory
sudo mkdir -p $root

# Assign ownership to your regular user account
sudo chown -R $user:$user $root

# Create the Nginx server block file:
sudo tee $block > /dev/null <<EOF
server {
        listen 80;
        listen [::]:80;

        root /var/www/$domain/html;
        index index.html index.htm;

        server_name $domain www.$domain;

        location / {
                try_files $uri $uri/ =404;
        }
}

server {

        root /home/$user/$domain/public;
        index index.php index.html index.htm;

        server_name $domain www.$domain;

        location / {
                try_files $uri $uri/ /index.php?$args;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.4-fpm-$user.sock;
        }

}


EOF

# Link to make it available
sudo ln -s $block /etc/nginx/sites-enabled/

# Test configuration and reload if successful
sudo nginx -t && sudo service nginx reload

. ../setup-database/setup.sh
