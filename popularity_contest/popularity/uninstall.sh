#!/bin/bash


if [[ -d /opt/popularity ]]; then
    rm -rf /opt/popularity
fi
mysql -e 'drop database popularity'

rm -rf /etc/apache2/conf-enabled/apache-flask.conf
