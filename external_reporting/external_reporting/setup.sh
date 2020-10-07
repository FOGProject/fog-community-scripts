#!/bin/bash

# This is written to work on Debian 10 minimal.
apt-get update
apt-get -y remove python
apt-get -y install apache2 libapache2-mod-wsgi-py3 python3-pip mariadb-server mariadb-client default-libmysqlclient-dev python3-mysqldb


## If a settings file exists, back it up.
if [[ -f /opt/external_reporting/settings.json ]]; then
    [[ -f /home/settings.json ]] && rm -f /home/settings.json
    cp /opt/external_reporting/settings.json /home/settings.json
fi


cp -r ../external_reporting /opt
cd /opt/external_reporting
rm -rf .git


## If we have a backed up settings file, put it back.
if [[ -f /home/settings.json ]]; then
    rm -f /opt/external_reporting/settings.json
    mv /home/settings.json /opt/external_reporting/settings.json
fi


pip3 install virtualenv 


virtualenv flask
# Note: Currently using mysql, but wanting to evaluate the mariadb module.
flask/bin/pip install flask mysql mariadb boto3


# Do not overwrite this file if it exists because Let's Encrypt makes changes to it that need to stay.
if [[ ! -f /etc/apache2/conf-enabled/apache-flask.conf ]]; then
    cp apache-flask.conf /etc/apache2/conf-enabled
fi


systemctl enable mariadb
systemctl restart mariadb
systemctl restart apache2


# If we already have a database called external_reporting, exit.
string=$(mysql -u root -e 'show databases' | grep 'external_reporting')
if [[ $string == *"external_reporting"* ]]; then
    exit
fi


# Uncomment this to drop database & start over.
#mysql -u root -e "drop database external_reporting"


# Setup database.
mysql -u root < db.sql


