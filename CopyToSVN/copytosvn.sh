#!/bin/bash
# Script perform copying of data.

# Prints dots to a defined set.
# Arguments:
#  $1 The string to pad right the dots.
dots() {
    local string="$1"
    local pad=$(printf "%0.1s" "."{1..60})
    printf " * %s%*.*s" "${string}" 0 $((60-${#string})) "${pad}"
}

# If error sent is not 0 exit from the
#  program and report failed.
# Arguments:
#  $1 The errorcode to test.
errorStat() {
    local error=$1
    if [[ ! $error -eq 0 ]]; then
        echo "Failed"
        exit 1
    fi
    echo "OK"
}

# Performs psr fixing of the files.
# Arguments:
#  $1 The path check.
psrfix() {
    local path="$1"
    [[ -z $path || ! -e $path ]] && errorStat 1
    dots "Updating php-cs-fixer"
    /usr/local/bin/php-cs-fixer self-update >/dev/null 2>&1
    errorStat "$?"
    dots "Fixing PSR Structures in php"
    /usr/local/bin/php-cs-fixer fix ${path} --rules=@PSR2 >/dev/null 2>&1
    echo "OK"
}

# Update the trunk files.
# Arguments:
#  $1 Test variable for full or branch.
trunkUpdate() {
    local testvar=$1
    local cwd=$(pwd)
	[[ $testvar == 'full' || -z $testvar ]] && testvar=""
	cd /root/fogproject
	dots "Updating GIT Directory"
	/usr/bin/git checkout $testvar >/dev/null 2>&1
	/usr/bin/git pull >/dev/null 2>&1
    errorStat "$?"
}

# Updates the version numbers.
# Arguments:
#  $1 The second is branch or typed as full.
versionUpdate() {
    local testvar=$1
    [[ $testvar == full ]] && channel="Stable"
    dots "Updating Version in File"
    local gitcom=$(git rev-list --tags --no-walk --max-count=1)
    [[ -z $trunkver ]] && trunkversion="$(git describe --tags $gitcom).$(git rev-list ${gitcom}..HEAD --count)" || trunkversion=${trunkver}
    sed -i "s/define('FOG_VERSION'.*);/define('FOG_VERSION', '$trunkversion');/g" /var/www/fog/lib/fog/system.class.php >/dev/null 2>&1
    [[ -z $channel ]] && channel="Alpha"
    sed -i "s/define('FOG_CHANNEL'.*);/define('FOG_CHANNEL', '$channel');/g" /var/www/fog/lib/fog/system.class.php >/dev/null 2>&1
    errorStat $?
}

copyFilesToTrunk() {
    local testvar=$1
    local path='/root/fogproject/packages/web/'
    dots "Removing any ~ files."
    find /var/www/fog/ -type f -name "*~" -exec rm -rf {} \; >/dev/null 2>&1
    errorStat $?
    dots "Copying files to git"
    rsync -a --no-links -heP --exclude maintenance --delete /var/www/fog/ $path >/dev/null 2>&1
    errorStat $?
    dots "Cleaning up"
	rm -rf /root/fogproject/packages/web/lib/fog/config.class.php >/dev/null 2>&1
	rm -rf /root/fogproject/packages/web/management/other/cache/* >/dev/null 2>&1
	rm -rf /root/fogproject/packages/web/management/other/ssl >/dev/null 2>&1
	rm -rf /root/fogproject/packages/web/status/injectHosts.php >/dev/null 2>&1
	find /root/fogproject/ -type f -name "*~" -exec rm -rf {} \; >/dev/null 2>&1
	[[ $testvar == 'full' ]] && \
		sed -i 's/^fullrelease=.*$/fullrelease="'${trunkver}'"/g' /root/fogproject/bin/installfog.sh || \
		sed -i 's/^fullrelease=.*$/fullrelease="0"/g' /root/fogproject/bin/installfog.sh
    errorStat $?
}

[[ -n $psrfix ]] && psrfix "/var/www/fog"
trunkUpdate $*
[[ $3 == update ]] && exit 0
#dots "Update language po/pot files"
#foglanguage.sh >/dev/null 2>&1
#errorStat $?
versionUpdate $*
copyFilesToTrunk $*
