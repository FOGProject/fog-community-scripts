#!/bin/bash
#
# Pins that a web -> git pull never carries a generated config.class.php into
# the checkout, at either of the two paths it can live at.
#
# Why this exists
# ---------------
# That file holds the database password, both FTP passwords and the schema
# token. It is gitignored (`*config.class.php` is a glob, so it matches at any
# depth), which means git will not COMMIT it -- and that is exactly what makes
# a miss here quiet: the secrets land in the working tree and nothing says so.
#
# The path moved on the PSR-4 branches, from lib/fog/ to commons/
# (FOGProject/fogproject#1429), and one script pulls from 1.5 and 1.6 servers
# alike. An exclude naming only the old spelling still passes every syntax and
# lint check while copying the new one straight in.
#
# The excludes array is extracted from copytosvn.sh and fed to a REAL rsync
# against fixture trees -- restating the list here would keep passing after the
# script changed. No webroot, no git checkout, no sudo, no network.
#
# Usage: bash CopyToSVN/test-config-not-pulled.sh
# Exit 0 = pass, 1 = fail.

set -uo pipefail

script="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/copytosvn.sh"
[[ -r $script ]] || { echo "FAIL: cannot read $script"; exit 1; }

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

arr=$work/excludes.sh
sed -n '/^excludes=(/,/^)$/p' "$script" > "$arr"
grep -q "lib/fog/config.class.php" "$arr" \
    || { echo "FAIL: excludes array not found in $script"; exit 1; }

failures=0
note() { echo "FAIL: $*"; failures=$((failures + 1)); }

web=$work/web
repo=$work/repo/packages/web
mkdir -p "$web/lib/fog" "$web/commons" "$web/management/other" "$repo"

# Both spellings present at once: a 1.6 server that was first installed under
# the old layout can genuinely carry both, and neither may be pulled.
echo "<?php class Config { const DB_PASS = 'secret'; }" > "$web/lib/fog/config.class.php"
echo "<?php class Config { const DB_PASS = 'secret'; }" > "$web/commons/config.class.php"
echo "<?php // fogpaths"    > "$web/commons/fogpaths.php"
echo "<?php // real source" > "$web/management/index.php"

(
    # shellcheck disable=SC1090
    source "$arr"
    rsync -a --no-links --delete "${excludes[@]}" "$web/" "$repo"
) >/dev/null 2>&1 || note "rsync exited non-zero"

# ---- the excludes, on their own -----------------------------------------
#
# Checked BEFORE the cleanup runs, deliberately. The cleanup deletes these
# files too, so asserting after it would go green with the excludes removed
# entirely -- the gate would be measuring the wrong half. The excludes are the
# half that matters: with them, rsync never writes the secrets to disk at all,
# rather than writing them and deleting them a few lines later, which leaves a
# window and leaves them behind for good if the script dies in between.
for rel in lib/fog/config.class.php commons/config.class.php; do
    if [[ -e $repo/$rel ]]; then
        note "$rel was RSYNCED into the checkout -- the exclude is missing"
    fi
done

# ---- the cleanup, on its own --------------------------------------------
#
# Belt to the excludes' braces, and not redundant: an rsync exclude is
# protected from --delete as well as from transfer, so a copy already sitting
# in the checkout from an older run SURVIVES the rsync precisely because it is
# excluded. Only this step removes it. Planted after the rsync so the
# assertion is about the cleanup and not about what rsync did.
mkdir -p "$repo/lib/fog" "$repo/commons"
echo "left over from an older run" > "$repo/lib/fog/config.class.php"
echo "left over from an older run" > "$repo/commons/config.class.php"

sed -n '/^rm -f "\$path\/packages\/web\/lib\/fog\/config.class.php"/,/^find "\$path\/packages\/web\/"/p' \
    "$script" > "$work/cleanup.sh"
grep -q 'commons/config.class.php' "$work/cleanup.sh" \
    || note "cleanup step does not remove commons/config.class.php"
( path=$work/repo; source "$work/cleanup.sh" ) >/dev/null 2>&1

for rel in lib/fog/config.class.php commons/config.class.php; do
    if [[ -e $repo/$rel ]]; then
        note "$rel survived the cleanup step"
    fi
done

# The excludes must not be so broad that real source stops being pulled.
[[ -f $repo/management/index.php ]] \
    || note "management/index.php was not pulled -- an exclude is too broad"

# fogpaths.php is installer-written and must stay excluded; pulling it in is
# how one server's FOG_BASE_DIR gets deployed onto another.
[[ -e $repo/commons/fogpaths.php ]] \
    && note "commons/fogpaths.php was pulled into the checkout"

# Nothing anywhere in the checkout may match the ignore glob.
found=$(find "$work/repo" -name 'config.class.php' | wc -l)
[[ $found -eq 0 ]] || note "found $found config.class.php file(s) under the checkout"

if [[ $failures -gt 0 ]]; then
    echo "$failures failure(s)"
    exit 1
fi
echo "config-not-pulled: both spellings excluded and swept, real source still pulled"
echo "PASS"
exit 0
