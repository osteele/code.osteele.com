#!/bin/bash -eu

apt-get update -qq
apt-get install -y apache2

echo 'ServerName blog.osteele.dev' > /etc/apache2/httpd.conf

a2enmod rewrite
a2enmod actions
a2enmod proxy
a2enmod proxy_http
a2enmod -q headers

a2dissite default

ln -fs /vagrant/build /var/www/code.osteele.com
ln -fs /vagrant/config/code.osteele.com.conf /etc/apache2/sites-available/code.osteele.com
a2ensite code.osteele.com

service apache2 restart
