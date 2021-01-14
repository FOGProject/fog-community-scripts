#!/bin/bash
path=$1
configpath=$2
[[ -z $path || ! -e "$HOME/$path" ]] && path="$HOME/fogproject"
[[ -z $configpath || ! -e "$configpath" ]] && configpath="$HOME/config.class.php"
[[ ! -e "$configpath" && -e /var/www/fog/lib/fog/config.class.php ]] && cp /var/www/fog/lib/fog/config.class.php $configpath
[[ ! -e $configpath ]] && {
    echo "No configuration file available. Please make sure this file exists"
    exit 1
}
rsync -a --no-links -heP --delete $path/packages/web/ /var/www/fog/
cp $configpath /var/www/fog/lib/fog/config.class.php
chown -R apache:apache /var/www/fog
chown -R fogproject:apache /var/www/fog/service/ipxe
