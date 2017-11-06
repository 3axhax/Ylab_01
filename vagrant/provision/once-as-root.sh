#!/usr/bin/env bash

#== Import script args ==

timezone=$(echo "$1")

#== Bash helpers ==

function info {
  echo " "
  echo "--> $1"
  echo " "
}

#== Provision script ==

info "Provision-script user: `whoami`"

info "Allocate swap for MySQL 5.6"
fallocate -l 2048M /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap defaults 0 0' >> /etc/fstab

info "Configure locales"
update-locale LC_ALL="C"
dpkg-reconfigure locales

info "Configure timezone"
echo ${timezone} | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

info "Prepare root password for MySQL"
debconf-set-selections <<< "mysql-server-5.6 mysql-server/root_password password \"''\""
debconf-set-selections <<< "mysql-server-5.6 mysql-server/root_password_again password \"''\""
echo "Done!"

info "Update OS software"
apt-get update
apt-get upgrade -y

info "Install additional software"
apt-get install -y git php5-curl php5-cli php5-intl php5-mysqlnd php5-gd php5-mcrypt php5-fpm nginx mysql-server-5.6

info "Configure MySQL"
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
echo "Done!"

info "Configure PHP-FPM"
sed -i 's/user = www-data/user = vagrant/g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/group = www-data/group = vagrant/g' /etc/php5/fpm/pool.d/www.conf
sed -i 's/owner = www-data/owner = vagrant/g' /etc/php5/fpm/pool.d/www.conf

sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php5/fpm/php.ini
sed -i 's/;mbstring.func_overload = 0/mbstring.func_overload = 2/g' /etc/php5/fpm/php.ini
sed -i 's/;mbstring.internal_encoding = UTF-8/mbstring.internal_encoding = UTF-8/g' /etc/php5/fpm/php.ini
sed -i 's/;date.timezone =/date.timezone = Europe\/Moscow/g' /etc/php5/fpm/php.ini
sed -i '/max_input_vars =/c\max_input_vars = 10000' /etc/php5/fpm/php.ini
sed -i '/upload_max_filesize =/c\upload_max_filesize = 100M' /etc/php5/fpm/php.ini
sed -i '/post_max_size =/c\post_max_size = 100M' /etc/php5/fpm/php.ini

php5enmod mcrypt
echo "Done!"

info "Configure NGINX"
sed -i 's/user www-data/user vagrant/g' /etc/nginx/nginx.conf
echo "Done!"

info "Enabling site configuration"
ln -s /app/vagrant/nginx/app.conf /etc/nginx/sites-enabled/app.conf
rm /etc/nginx/sites-enabled/default
echo "Done!"

info "Initailize databases for MySQL"
mysql -uroot <<< "CREATE DATABASE bitrix CHARACTER SET utf8"
echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
