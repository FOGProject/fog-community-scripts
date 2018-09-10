#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


#Test the installer.
$cwd/./test_install.sh 

#Test imaging.
#$cwd/./test_imaging.sh


rsync -r /var/www/html fogtesting:/var/www

