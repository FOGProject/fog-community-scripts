#!/bin/bash
path=$1
[[ -z $path || ! -e ~/$path ]] && path="~/trunk"
rsync -a --no-links -heP ~/$path/packages/web/ /var/www/fog/
rsync -a --no-links -heP --exclude=fog --delete ~/$path/packages/web/ /var/www/fog/
cp ~/config.class.php /var/www/fog/lib/fog/config.class.php
chown -R apache:apache /var/www/fog
chown -R 500:apache /var/www/fog/service/ipxe
