#!/bin/bash

# This is written to work on Debian 10 minimal.

apt-get update
apt-get -y remove python
apt-get -y install apache2 libapache2-mod-wsgi-py3 python3-pip mariadb-server mariadb-client default-libmysqlclient-dev python3-mysqldb

## If a settings file exists, back it up.
if [[ -f /opt/popularity/settings.json ]]; then
    [[ -f /home/settings.json ]] && rm -f /home/settings.json
    cp /opt/popularity/settings.json /home/settings.json
fi

cp -r ../popularity /opt
cd /opt/popularity
rm -rf .git

## If we have a backed up settings file, put it back.
if [[ -f /home/settings.json ]]; then
    rm -f /opt/popularity/settings.json
    mv /home/settings.json /opt/popularity/settings.json
fi

pip3 install virtualenv 

virtualenv flask
# Note: Currently using mysql, but wanting to evaluate the mariadb module.
flask/bin/pip install flask mysql mariadb


if [[ -f /etc/apache2/conf-enabled ]]; then
    rm -f /etc/apache2/conf-enabled
fi

cp apache-flask.conf /etc/apache2/conf-enabled
#chown -R www-data:www-data app
#chown -R www-data:www-data wsgi.py

systemctl enable mariadb
systemctl restart mariadb
systemctl restart apache2

# If we already have a database called popularity, exit.
string=$(mysql -u root -e 'show databases' | grep 'popularity')
if [[ $string == *"popularity"* ]]; then
    exit
fi

# Uncomment this to drop database & start over.
#mysql -u root -e "drop database popularity"

# Setup database.
mysql -u root < db.sql


