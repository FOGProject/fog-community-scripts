#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"

#If repository exists, git pull. Else clone it.
if [[ -d ${HOME}/git/fogproject ]]; then
    git -C ${HOME}/git/fogproject pull
else
    git -C ${HOME}/git/fogproject clone https://github.com/FOGProject/fogproject.git
fi

didMaster="no"
didDev="no"


$cwd/./restoreSnapshots.sh clean
$cwd/./rebootVMs.sh
$cwd/./updateNodeOSs.sh
$cwd/./rebootVMs.sh
$cwd/./updateNodeOSs.sh updated


#Get last x branches.
for branch in $(git -C ${HOME}/git/fogproject for-each-ref --count=2 --sort=-committerdate --format='%(refname:short)'); do 

    if [[ "$branch" == "master" ]]; then
        didMaster="yes"
    fi
    if [[ "$branch" == "dev-branch" ]]; then
        didDev="yes"
    fi

    #Remove everything before first "/" in branch name.
    branch="${branch##*/}"


    if [[ "$branch" == "master" ]]; then
        didMaster="yes"
    fi
    if [[ "$branch" == "dev-branch" ]]; then
        didDev="yes"
    fi

    $cwd/./restoreSnapshots.sh updated
    $cwd/./updateNodeFOGs.sh



done


if [[ "$didMaster" == "no" ]]; then
    branch="master"
    $cwd/./restoreSnapshots.sh updated
    $cwd/./updateNodeFOGs.sh
fi

if [[ "$didDev" == "no" ]]; then
    branch="dev-branch"
    $cwd/./restoreSnapshots.sh updated
    $cwd/./updateNodeFOGs.sh
fi

$cwd/./deleteSnapshots.sh updated




