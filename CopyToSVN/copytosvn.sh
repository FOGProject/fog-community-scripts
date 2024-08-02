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
    cd $HOME/fogproject
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
    local gitbranch=$(git branch | awk '/*/ {print $2}')
    local gitcom=$(git rev-list --tags --no-walk --max-count=1)
    local gitcount=$(git rev-list ${gitcom}..HEAD --count)
    local branchon=$(echo ${gitbranch} | awk -F'-' '{print $1}')
    local branchend=$(echo ${gitbranch} | awk -F'-' '{print $2}')
    local verbegin=""
    case $branchon in
        dev)
            verbegin="$(git describe --tags ${gitcom})."
            channel="Patches"
            ;;
        working)
            verbegin="${branchend}.0-beta."
            channel="Beta"
            ;;
        master)
            [[ -z $trunkver ]] && trunkver="$(git describe --tags ${gitcom})"
            channel="Release"
            ;;
        rc)
            verbegin="rc-${branchend}."
            channel="Release Candidate"
            ;;
    esac
    [[ -z $trunkver ]] && trunkversion="${verbegin}${gitcount}" || trunkversion=${trunkver}
    sed -i "s/define('FOG_VERSION'.*);/define('FOG_VERSION', '$trunkversion');/g" $HOME/fogproject/packages/web/lib/fog/system.class.php >/dev/null 2>&1
    [[ -z $channel ]] && channel="Alpha"
    sed -i "s/define('FOG_CHANNEL'.*);/define('FOG_CHANNEL', '$channel');/g" $HOME/fogproject/packages/web/lib/fog/system.class.php >/dev/null 2>&1
    errorStat $?
}

copyFilesToTrunk() {
    local testvar=$1
    local path='$HOME/fogproject/packages/web/'
    dots "Removing any ~ files."
    find /var/www/fog/ -type f -name "*~" -exec rm -rf {} \; >/dev/null 2>&1
    errorStat $?
    dots "Copying files to git"
    rsync -a --no-links -heP --exclude maintenance --delete /var/www/fog/ $HOME/fogproject/packages/web >/dev/null 2>&1
    errorStat $?
    dots "Cleaning up"
    rm -rf $HOME/fogproject/packages/web/lib/fog/config.class.php >/dev/null 2>&1
    rm -rf $HOME/fogproject/packages/web/management/other/cache/* >/dev/null 2>&1
    rm -rf $HOME/fogproject/packages/web/management/other/ssl >/dev/null 2>&1
    rm -rf $HOME/fogproject/packages/web/status/injectHosts.php >/dev/null 2>&1
    find $HOME/fogproject/ -type f -name "*~" -exec rm -rf {} \; >/dev/null 2>&1
    [[ $testvar == 'full' ]] && \
        sed -i 's/^fullrelease=.*$/fullrelease="'${trunkver}'"/g' $HOME/fogproject/bin/installfog.sh || \
        sed -i 's/^fullrelease=.*$/fullrelease="0"/g' $HOME/fogproject/bin/installfog.sh
    errorStat $?
}

updateLanguage() {
    xgettext --language=PHP --from-code=UTF-8 --output="$HOME/fogproject/packages/web/management/languages/messages.pot" --omit-header --no-location $(find $HOME/fogproject/packages/web/ -name "*.php")
    msgcat --sort-output -o "$HOME/fogproject/packages/web/management/languages/messages.pot" "$HOME/fogproject/packages/web/management/languages/messages.pot"
    for PO_FILE in $(find $HOME/fogproject/packages/web/management/languages/ -type f -name *.po); do
        msgmerge --update --backup=none $PO_FILE $HOME/fogproject/packages/web/management/languages/messages.pot 2>/dev/null >/dev/null
        msgcat --sort-output -o $PO_FILE $PO_FILE
    done
}

[[ -n $psrfix ]] && psrfix "/var/www/fog"
trunkUpdate $*
[[ $3 == update ]] && exit 0
#dots "Update language po/pot files"
#foglanguage.sh >/dev/null 2>&1
#errorStat $?
copyFilesToTrunk $*
updateLanguage $*
versionUpdate $*
