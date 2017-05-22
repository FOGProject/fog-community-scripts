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
#  $1 The first argument either blank or git/svn.
#  $2 Test variable for full or branch.
trunkUpdate() {
    local type=$1
    local testvar=$2
    local cwd=$(pwd)
    case $type in
        git)
            [[ $testvar == 'full' || -z $testvar ]] && testvar=""
            cd /root/fogproject
            dots "Updating GIT Directory"
            /usr/local/bin/git checkout $testvar >/dev/null 2>&1
            /usr/local/bin/git pull >/dev/null 2>&1
            ;;
        *)
            cd /root/trunk
            dots "Updating SVN Directory"
            /usr/bin/svn update >/dev/null 2>&1
            ;;
    esac
    errorStat "$?"
}

# Updates the version numbers.
# Arguments:
#  $1 Not used but is passed.
#  $2 The second is branch or typed as full.
versionUpdate() {
    local testvar=$2
    local full=1
    [[ $testvar == full ]] && full=2
    dots "Updating Version in File"
    [[ -z $trunkver ]] && trunkversion=$(git describe --tags | awk -F'-[^0-9]*' '{gsub(/[^0-9]/,"",$3); gsub(/[^0-9]/,"",$2); value=$2+$3+1; print value}') >/dev/null 2>&1 || trunkversion=${trunkver}
    sed -i "s/define('FOG_VERSION'.*);/define('FOG_VERSION', '$trunkversion');/g" /var/www/fog/lib/fog/system.class.php >/dev/null 2>&1
    svn up /root/trunk >/dev/null 2>&1
    svnver=$(($(svnversion /root/trunk | cut -dM -f1) + $full));
    sed -i "s/define('FOG_SVN_REVISION'.*;/define('FOG_SVN_REVISION', $svnver);/g" /var/www/fog/lib/fog/system.class.php >/dev/null 2>&1
    sed -i "s///g" /var/www/fog/lib/fog/system.class.php >/dev/null 2>&1
    errorStat $?
}

copyFilesToTrunk() {
    local type=$1
    local testvar=$2
    local path=''
    dots "Removing any ~ files."
    find /var/www/fog/ -type f -name "*~" -exec rm -rf {} \; >/dev/null 2>&1
    errorStat $?
    case $type in
        git)
            path='/root/fogproject/packages/web/'
            ;;
        *)
            path='/root/trunk/packages/web/'
            ;;
    esac
    dots "Copying files to trunk"
    rsync -a --no-links -heP /var/www/fog/ $path >/dev/null 2>&1
    errorStat $?
    dots "Cleaning up"
    case $type in
        git)
            rm -rf /root/fogproject/packages/web/lib/fog/config.class.php >/dev/null 2>&1
            rm -rf /root/fogproject/packages/web/management/other/cache/* >/dev/null 2>&1
            rm -rf /root/fogproject/packages/web/management/other/ssl >/dev/null 2>&1
            rm -rf /root/fogproject/packages/web/status/injectHosts.php >/dev/null 2>&1
            find /root/fogproject/ -type f -name "*~" -exec rm -rf {} \; >/dev/null 2>&1
            rsync -a --no-links -heP /root/fogproject/ /root/trunk2/ >/dev/null 2>&1
            [[ $testvar == 'full' ]] && \
                sed -i 's/^fullrelease=.*$/fullrelease="'${trunkver}'"/g' /root/fogproject/bin/installfog.sh || \
                sed -i 's/^fullrelease=.*$/fullrelease="0"/g' /root/fogproject/bin/installfog.sh
            ;;
        *)
            rm -rf /root/trunk/packages/web/lib/fog/config.class.php >/dev/null 2>&1
            rm -rf /root/trunk/packages/web/management/other/cache/* >/dev/null 2>&1
            rm -rf /root/trunk/packages/web/management/other/ssl >/dev/null 2>&1
            rm -rf /root/trunk/packages/web/status/injectHosts.php >/dev/null 2>&1
            find /root/trunk/ -type f -name "*~" -exec rm -rf {} \; >/dev/null 2>&1
            rsync -a --no-links -heP /root/trunk/ /root/trunk2/ >/dev/null 2>&1
            [[ $testvar == 'full' ]] && \
                sed -i 's/^fullrelease=.*$/fullrelease="'${trunkver}'"/g' /root/trunk/bin/installfog.sh || \
                sed -i 's/^fullrelease=.*$/fullrelease="0"/g' /root/trunk/bin/installfog.sh
            ;;
    esac
    errorStat $?
}

makefogtar() {
    [[ -z $trunkver ]] && trunkver='trunk';
    rm -rf /opt/fog_trunk
    if [[ -z $1 || $1 == svn ]]; then
        cp -r /root/trunk /opt/fog_${trunkver}
    elif [[ $1 == git ]]; then
        cp -r /root/fogproject /opt/fog_${trunkver}
    fi
    if [[ ! -e /opt/fog_${trunkver}/binaries${trunkver}.zip ]]; then
        dots "Downloading binaries if able"
        curl --silent -ko "/opt/fog_${trunkver}/binaries${trunkver}.zip" "https://fogproject.org/binaries${trunkver}.zip" >/dev/null 2>&1
        local stat="$?"
        [[ ! $stat -eq 0 ]] && rm -rf "/opt/fog_${trunkver}/binaries${trunkver}.zip" >/dev/null 2>&1
        echo "Done"
    fi
    cd /opt/fog_${trunkver}
    svn cleanup >/dev/null 2>&1
    svn revert -R . >/dev/null 2>&1
    git clean -fd >/dev/null 2>&1
    git reset --hard >/dev/null 2>&1
    find /opt/fog_${trunkver} -regex '.*\(\.git\|\.svn\)$' -exec rm -rf {} \; >/dev/null 2>&1
    cd /opt
    dots "Creating FOG Tar File (bzip)"
    tar -cjf /var/www/html/fog_${trunkver}.tar.bz2 fog_${trunkver}
    echo "Done"
    dots "Creating FOG Tar File (gzip)"
    tar -czf /var/www/html/fog_${trunkver}.tar.gz fog_${trunkver}
    echo "Done"
    dots "Removing working directory"
    rm -rf /opt/fog_${trunkver}
    echo "Done"
    cd $cwd
    unset cwd
}
[[ -n $psrfix ]] && psrfix "/var/www/fog"
trunkUpdate $*
[[ $3 == update ]] && exit 0
dots "Update language po/pot files"
foglanguage.sh >/dev/null 2>&1
errorStat $?
versionUpdate $*
copyFilesToTrunk $*
makefogtar $*
