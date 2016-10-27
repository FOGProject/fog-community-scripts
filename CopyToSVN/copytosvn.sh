#!/bin/bash
dots() {
    local pad=$(printf "%0.1s" "."{1..60})
    printf " * %s%*.*s" "$1" 0 $((60-${#1})) "$pad"
}
errorStat() {
    if [ "$1" != 0 ]; then
        echo "Failed"
        exit 1
    fi
    echo "OK"
}
trunkUpdate() {
    cwd=`pwd`
    if [[-z $1 || $1 == svn]]; then
        cd /root/trunk
        dots "Updating SVN Directory"
        /usr/bin/svn update >/dev/null 2>&1
        cd /root/fogproject
    elif [[$1 == git]]; then
        dots "Updating GIT Directory"
        cd /root/fogproject
        /usr/bin/git checkout dev-branch >/dev/null 2>&1
        /usr/bin/git pull >/dev/null 2>&1
    fi
    errorStat $?
}
versionUpdate() {
    dots "Updating Version in File"
    trunkver=`git describe --tags | awk -F'-[^0-9]*' '{value=$2+$3+1; print value}'` >/dev/null 2>&1
    sed -i "s/define('FOG_VERSION'.*);/define('FOG_VERSION', '$trunkver');/g" /var/www/fog/lib/fog/system.class.php >/dev/null 2>&1
//g" /var/www/fog/lib/fog/system.class.php >/dev/null 2>&1
    errorStat $?
}
copyFilesToTrunk() {
    dots "Copying files to trunk"
    for filename in `find /var/www/fog -type d`; do
        if [[-z $1 || $1 == svn]]; then
            cp -r $filename/* /root/trunk/packages/web/${filename#/var/www/fog} >/dev/null 2>&1
        elif [[$1 == git]]; then
            cp -r $filename/* /root/fogproject/packages/web/${filename#/var/www/fog} >/dev/null 2>&1
        fi
    done
    if [[-z $1 || $1 == svn]]; then
        rm -rf /root/trunk/packages/web/lib/fog/config.class.php >/dev/null 2>&1
        rm -rf /root/trunk/packages/web/management/other/cache/* >/dev/null 2>&1
        rm -rf /root/trunk/packages/web/management/other/ssl >/dev/null 2>&1
        rm -rf /root/trunk/packages/web/status/injectHosts.php >/dev/null 2>&1
        rm -rf /root/trunk2/* >/dev/null 2>&1
        cp -r /root/trunk/* /root/trunk2/ >/dev/null 2>&1
    elif [[$1 == git]]; then
        rm -rf /root/fogproject/packages/web/lib/fog/config.class.php >/dev/null 2>&1
        rm -rf /root/fogproject/packages/web/management/other/cache/* >/dev/null 2>&1
        rm -rf /root/fogproject/packages/web/management/other/ssl >/dev/null 2>&1
        rm -rf /root/fogproject/packages/web/status/injectHosts.php >/dev/null 2>&1
        rm -rf /root/trunk2/* >/dev/null 2>&1
        cp -r /root/fogproject/* /root/trunk2/ >/dev/null 2>&1
    fi
    errorStat $?
}
makefogtar() {
    dots "Creating FOG Tar File"
    rm -rf /opt/fog_trunk
    if [[-z $1 || $1 == svn]]; then
        cp -r /root/trunk /opt/fog_trunk
        find /opt/fog_trunk -name .svn -exec rm -rf {} \; >/dev/null 2>&1
    elif [[$1 == git]]; then
        cp -r /root/fogproject /opt/fog_trunk
        find /opt/fog_trunk -name .git -exec rm -rf {} \; >/dev/null 2>&1
    fi
    cd /opt
    tar -cjf /var/www/html/fog_trunk.tar.bz2 fog_trunk
    rm -rf /opt/fog_trunk
    cd $cwd
    unset cwd
    errorStat $?
}
trunkUpdate $1
versionUpdate $1
copyFilesToTrunk $1
makefogtar $1
