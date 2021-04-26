#!/bin/bash
adduser $1
usermod -aG sudo $1

user=$1
domain=$2
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
                try_files \$uri \$uri/ /index.php?\$args;
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

sudo service php7.4-fpm restart

# If /root/.my.cnf exists then it won't ask for root password
if [ -f /root/.my.cnf ]; then
	echo "Please enter the NAME of the new MySQL database! (example: database1)"
	read dbname
	echo "Please enter the MySQL database CHARACTER SET! (example: latin1, utf8, ...)"
	echo "Enter utf8 if you don't know what you are doing"
	read charset
	echo "Creating new MySQL database..."
	mysql -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET ${charset} */;"
	echo "Database successfully created!"
	echo "Showing existing databases..."
	mysql -e "show databases;"
	echo ""
	echo "Please enter the NAME of the new MySQL database user! (example: user1)"
	read username
	echo "Please enter the PASSWORD for the new MySQL database user!"
	echo "Note: password will be hidden when typing"
	read -s userpass
	echo "Creating new user..."
	mysql -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"
	echo ""
	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
	exit
	
# If /root/.my.cnf doesn't exist then it'll ask for root password	
else
	echo "Please enter root user MySQL password!"
	echo "Note: password will be hidden when typing"
	read -s rootpasswd
	echo "Please enter the NAME of the new MySQL database! (example: database1)"
	read dbname
	echo "Please enter the MySQL database CHARACTER SET! (example: latin1, utf8, ...)"
	echo "Enter utf8 if you don't know what you are doing"
	read charset
	echo "Creating new MySQL database..."
	mysql -uroot -p${rootpasswd} -e "CREATE DATABASE ${dbname} /*\!40100 DEFAULT CHARACTER SET ${charset} */;"
	echo "Database successfully created!"
	echo "Showing existing databases..."
	mysql -uroot -p${rootpasswd} -e "show databases;"
	echo ""
	echo "Please enter the NAME of the new MySQL database user! (example: user1)"
	read username
	echo "Please enter the PASSWORD for the new MySQL database user!"
	echo "Note: password will be hidden when typing"
	read -s userpass
	echo "Creating new user..."
	mysql -uroot -p${rootpasswd} -e "CREATE USER ${username}@localhost IDENTIFIED BY '${userpass}';"
	echo "User successfully created!"
	echo ""
	echo "Granting ALL privileges on ${dbname} to ${username}!"
	mysql -uroot -p${rootpasswd} -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${username}'@'localhost';"
	mysql -uroot -p${rootpasswd} -e "FLUSH PRIVILEGES;"
	echo "You're good now :)"
	exit
fi
