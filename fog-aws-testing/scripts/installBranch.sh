#!/bin/bash
#
# Automates installation of FOG.
# Arguments:
#  $1 The branch to checkout/pull from.
branch=$1
# writes error code to /root/result
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
output="/root/result"

[[ -z $branch ]] && echo "1" > $output
export PATH="$PATH:/usr/bin/core_perl"

cd /root/git/fogproject >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && echo "5" > $output


git reset --hard >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && echo "2" > $output


git pull >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && echo "3" > $output


git checkout $branch >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && echo "4" > $output


git pull >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && echo "2" > $output


cd bin >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && echo "5" > $output


./installfog.sh -y >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && echo "6" > $output

# Here, we completed successfully.
echo "0" > $output


