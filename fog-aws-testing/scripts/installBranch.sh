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
usage() {
    local errCode=$1
    echo "Usage $0 <branch>"
	exit $errCode
}
[[ -z $branch ]] && exit 1
export PATH="$PATH:/usr/bin/core_perl"

cd /root/git/fogproject >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && exit 5
git reset --hard >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && exit 2
git pull >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && exit 3
git checkout $branch >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && exit 4
git pull >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && exit 2
cd bin >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && exit 5
./installfog.sh -y >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && exit 6
exit 0
