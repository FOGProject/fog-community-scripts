#!/bin/bash
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$cwd/settings.sh"


$cwd/./restoreSnapshots.sh clean
$cwd/./rebootVMs.sh
$cwd/./customCommand.sh
$cwd/./updateNodeOSs.sh
$cwd/./rebootVMs.sh

