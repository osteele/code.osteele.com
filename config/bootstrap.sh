#!/bin/bash -eu

apt-get update
apt-get install -y apache2
a2enmod rewrite
a2enmod actions

rm -f /etc/apache2/sites-enabled/000-default
ln -fs /vagrant/config/code.osteele.com.conf /etc/apache2/sites-enabled/
ln -fs /vagrant /var/www/code.osteele.com

service apache2 restart
