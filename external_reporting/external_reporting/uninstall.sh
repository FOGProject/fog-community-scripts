#!/bin/bash


if [[ -d /opt/external_reporting ]]; then
    rm -rf /opt/external_reporting
fi
mysql -e 'drop database external_reporting'

rm -rf /etc/apache2/conf-enabled/apache-flask.conf
