#!/bin/bash

. ../setup-user/setup.sh

domain=$1
user=$2
root="/home/$user/$domain/public"
nginx_file="/etc/nginx/sites-available/$domain"
php_fpm_file="/etc/php/7.4/fpm/pool.d/$user.conf"

# Create the Document Root directory
sudo mkdir -p $root

# Assign ownership to your regular user account
sudo chown -R $user:$user $root

# Create the Nginx server block file:
sudo tee $nginx_file > /dev/null <<EOF

server {

        root /home/$user/$domain/public;
        index index.php index.html index.htm;

        server_name $domain www.$domain;

        location / {
                try_files \$uri \$uri/ /index.php?$args;
        }

        location ~ \.php$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/run/php/php7.4-fpm-$user.sock;
        }

}


EOF

# Link to make it available
sudo ln -s $nginx_file /etc/nginx/sites-enabled/

# Test configuration and reload if successful
sudo nginx -t && sudo service nginx reload

# Create the PHP-FPM config file:
sudo tee $php_fpm_file > /dev/null <<EOF

[$user]

user = $user
group = $user

listen = /run/php/php7.4-fpm-$user.sock

listen.owner = www-data
listen.group = www-data

pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3

EOF

. ../setup-database/setup.sh
