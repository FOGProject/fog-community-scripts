#!/bin/bash
#
# Automates installation of FOG.
# Arguments:
#  $1 The branch to checkout/pull from.
branch=$1
# Returns Error code, will exit with same error code.
#  Error 1 = Failed to call script properly.
#  Error 2 = Failed to reset git.
#  Error 3 = Failed to pull git.
#  Error 4 = Failed to checkout git.
#  Error 5 = Failed to change directory.
#  Error 6 = Installation failed.
#  All else "success".
error() {
    local errCode=$1
        case $errCode in
            2) echo "Failed to reset git" ;;
            3) echo "Failed to pull git" ;;
            4) echo "Failed to checkout git" ;;
            5) echo "Failed to change directory" ;;
            6) echo "Installation failed" ;;
            *) exit 0 ;;
        esac
        exit $errCode
}
usage() {
    local errCode=$1
    echo "Usage $0 <branch>"
	exit $errCode
}
[[ -z $branch ]] && usage 1
export PATH="$PATH:/usr/bin/core_perl"
cd /root/git/fogproject >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && error 5
git reset --hard >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && error 2
git pull >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && error 3
git checkout $branch >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && error 4
git pull >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && error 2
cd bin >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && error 5
./installfog -y >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && error 6
error 0
