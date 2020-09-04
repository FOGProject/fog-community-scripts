#!/bin/bash
#
# Automates installation of FOG.
# Arguments:
#  $1 The branch to checkout/pull from.
branch=$1
install_timeout=$2
# writes error code to /root/result
#  Error 1 = Failed to call script properly.
#  Error 2 = Failed to reset git.
#  Error 3 = Failed to pull git.
#  Error 4 = Failed to checkout git.
#  Error 5 = Failed to change directory.
#  Error 6 = Installation failed.
#  Error 7 = Installation didn't complete in time.
#  All else "success".
usage() {
    local errCode=$1
    echo "Usage $0 <branch>"
    exit $errCode
}
result="/root/result"
output="/root/output"

[[ -z $branch ]] && printf "1" > $result
[[ -z $branch ]] && exit 1
export PATH="$PATH:/usr/bin/core_perl"

cd /root/git/fogproject >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && printf "5" > $result
[[ ! $stat -eq 0 ]] && exit $stat

git reset --hard >/dev/null 2>&1 && git clean -fdx >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && printf "2" > $result
[[ ! $stat -eq 0 ]] && exit $stat


git pull >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && printf "3" > $result
[[ ! $stat -eq 0 ]] && exit $stat


git checkout $branch >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && printf "4" > $result
[[ ! $stat -eq 0 ]] && exit $stat


git pull >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && printf "3" > $result
[[ ! $stat -eq 0 ]] && exit $stat


cd bin >/dev/null 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && printf "5" > $result
[[ ! $stat -eq 0 ]] && exit $stat

# Here, echo 7 to result file while we wait for installer to complete.
# If the installer does not complete in time, orchestrator will retrieve 7, indicating the same.
# If we complete in-time, this is overwritten.
printf "7" > $result
./installfog.sh -y > $output 2>&1
stat=$?
[[ ! $stat -eq 0 ]] && printf "6" > $result
[[ ! $stat -eq 0 ]] && exit $stat

# Here, we completed successfully.
printf "0" > $result


