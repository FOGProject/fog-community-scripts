#!/bin/bash


#If repository exists, git pull. Else clone it.
if [[ -d ${HOME}/git/fogproject ]]; then
    git -C ${HOME}/git/fogproject pull
else
    git -C ${HOME}/git/fogproject clone https://github.com/FOGProject/fogproject.git
fi

echo date > $report
echo "${cwd}"

#Get last x branches.
for branch in $(git -C ${HOME}/git/fogproject for-each-ref --count=10 --sort=-committerdate --format='%(refname:short)'); do 
    echo "################################################" >> $report
    echo "# Testing branch: $branch" >> $report
    echo "# Restoring snapshot $snapshotName to all test boxes." >> $report
    ${cwd}/./restoreSnapshots.sh
    echo "# Updating the OS for all text boxes." >> $report
    ${cwd}/./updateNodeOSs.sh
    echo "Installing latest commit from branch $branch onto all test boxes." >> $report
    ${cwd}/./updateNodeFOGs.sh.sh



done




