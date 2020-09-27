#!/bin/bash


if [[ -d /opt/analytics ]]; then
    rm -rf /opt/analytics
fi
mysql -e 'drop database analytics'

rm -rf /etc/apache2/conf-enabled/apache-flask.conf
