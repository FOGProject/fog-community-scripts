#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"




#If repository exists, git pull. Else clone it.
if [[ -d $gitDir/fogproject ]]; then
    echo "Directory exists, updating fogproject"
    mkdir -p $gitDir/fogproject
    cd $gitDir/fogproject;git pull;cd $cwd
else
    echo "Directory does not exist, cloning"
    git clone https://github.com/FOGProject/fogproject.git $gitDir/fogproject
fi

didMaster="no"
didDev="no"


$cwd/./restoreSnapshots.sh clean
$cwd/./rebootVMs.sh
$cwd/./updateNodeOSs.sh
$cwd/./rebootVMs.sh
$cwd/./updateNodeOSs.sh updated


#Get last x branches.
for branch in $(cd $gitDir/fogproject;git for-each-ref --count=3 --sort=-committerdate --format='%(refname:short)';cd $cwd); do 

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




