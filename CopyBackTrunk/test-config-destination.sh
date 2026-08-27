#!/bin/bash
#
# Pins where copybacktrunk.sh puts the generated config, and that it retires
# the copy at the other path.
#
# Why this exists
# ---------------
# The config moved from packages/web/lib/fog/ to packages/web/commons/ on the
# PSR-4 branches (FOGProject/fogproject#1429). One script deploys both layouts,
# so the destination is probed from the checkout -- and a webroot first
# deployed under the old layout keeps its old copy, because an rsync exclude
# is protected from --delete as well as from transfer. Two files then declare
# class Config inside a scanned root and FOG boots off whichever the scan
# reaches first, with a generated credential store left at the loser's path.
#
# Neither half of that is visible at runtime, which is why it is pinned here
# rather than left to a deploy to discover.
#
# The block under test is extracted from copybacktrunk.sh by its own anchors,
# not restated -- a copy of the logic would keep passing after the real script
# changed. sudo is stubbed to a passthrough; nothing here needs root, touches
# a real webroot, or runs rsync.
#
# Usage: bash CopyBackTrunk/test-config-destination.sh
# Exit 0 = pass, 1 = fail.

set -uo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/copybacktrunk.sh"
[[ -r $script ]] || { echo "FAIL: cannot read $script"; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Extract one contiguous range: the destination probe through the end of the
# retirement block. Awk rather than a sed range because there are two `fi`s in
# it, and the first would end a naive range halfway.
block=$work/block.sh
awk '/^if \[\[ -d \$path\/packages\/web\/src \]\]; then$/ { on = 1 }
     on { print }
     on && /rmdir --ignore-fail-on-non-empty/ { seen = 1; next }
     seen && /^fi$/ { exit }' "$script" > "$block"

grep -q 'configdest="commons/config.class.php"' "$block" \
    || { echo "FAIL: destination probe not found in $script"; exit 1; }
grep -q 'rm -f "\${webroot}/\${configstale}"' "$block" \
    || { echo "FAIL: retirement block not found in $script"; exit 1; }
# The awk range ends on the rmdir line. If that line ever changes, the range
# runs on into the ownership fixups and the failures that follow are about
# unbound variables rather than about the config -- so say so here instead.
grep -q 'chown' "$block" \
    && { echo "FAIL: extraction overran the block -- its end anchor moved"; exit 1; }

failures=0
note() { echo "FAIL: $*"; failures=$((failures + 1)); }

# $1 = case label, $2 = "psr4" or "legacy", $3 = pre-existing config rel path
# ("" for a fresh webroot), $4 = expected destination, $5 = path expected gone
run_case() {
    local label=$1 layout=$2 pre=$3 want=$4 gone=$5
    local root=$work/$label
    rm -rf "$root"
    mkdir -p "$root/checkout/packages/web" "$root/webroot/commons" \
             "$root/webroot/lib/fog"

    [[ $layout == psr4 ]] && mkdir -p "$root/checkout/packages/web/src"
    # commons/ always has another file, so its rmdir must be a no-op.
    echo "<?php // fogpaths" > "$root/webroot/commons/fogpaths.php"
    echo "<?php class Config { /* template */ }" > "$root/template.php"
    [[ -n $pre ]] && echo "<?php class Config { /* PREVIOUS DEPLOY */ }" \
        > "$root/webroot/$pre"
    [[ -z $pre ]] && rmdir "$root/webroot/lib/fog"

    (
        set -uo pipefail
        sudo() { "$@"; }
        path=$root/checkout
        webroot=$root/webroot
        configpath=$root/template.php
        # shellcheck disable=SC1090
        source "$block"
    ) > "$root/out.txt" 2>&1
    local rc=$?

    [[ $rc -eq 0 ]] || note "$label: block exited $rc -- $(cat "$root/out.txt")"

    if [[ ! -s $root/webroot/$want ]]; then
        note "$label: expected the config at $want, tree has:" \
             "$(cd "$root/webroot" && find . -name 'config.class.php' | tr '\n' ' ')"
    elif ! grep -q template "$root/webroot/$want"; then
        note "$label: $want is not the freshly copied template"
    fi

    if [[ -e $root/webroot/$gone ]]; then
        note "$label: $gone survived -- two files declare class Config"
    fi

    # Exactly one, always. This is the assertion the bug fails.
    local n
    n=$(cd "$root/webroot" && find . -name 'config.class.php' | wc -l)
    [[ $n -eq 1 ]] || note "$label: expected 1 config.class.php in the webroot, found $n"

    # commons/ must survive its rmdir; it holds fogpaths.php, whose loss is a
    # fatal undefined-constant on every page.
    [[ -f $root/webroot/commons/fogpaths.php ]] \
        || note "$label: commons/fogpaths.php was removed"
}

run_case psr4-over-legacy   psr4   lib/fog/config.class.php \
    commons/config.class.php  lib/fog/config.class.php
run_case psr4-fresh         psr4   "" \
    commons/config.class.php  lib/fog/config.class.php
run_case psr4-idempotent    psr4   commons/config.class.php \
    commons/config.class.php  lib/fog/config.class.php
run_case legacy-over-psr4   legacy commons/config.class.php \
    lib/fog/config.class.php  commons/config.class.php
run_case legacy-fresh       legacy "" \
    lib/fog/config.class.php  commons/config.class.php

# The empty lib/fog/ directory is swept on a PSR-4 deploy: the repo no longer
# has it, and leaving it invites the next hand-copy back into it.
if [[ -d $work/psr4-over-legacy/webroot/lib/fog ]]; then
    note "psr4-over-legacy: empty lib/fog/ was left behind"
fi

if [[ $failures -gt 0 ]]; then
    echo "$failures failure(s)"
    exit 1
fi
echo "config-destination: 5 cases pass"
echo "PASS"
exit 0
