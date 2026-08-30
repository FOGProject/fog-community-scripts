#!/bin/bash
#
# Pins that a git -> web deploy restarts the FOG daemons that are running, and
# only those.
#
# Why this exists
# ---------------
# The daemons' entry points live in /opt/fog/service, which copybacktrunk.sh
# does not deploy. Until FOG's PSR-4 move each entry point also carried its own
# copy of the service loop, so a webroot deploy genuinely did not change what a
# running daemon executed. It does now -- the entry points are three-line stubs
# and the loop is packages/web/src/Service/, inside the tree the script rsyncs.
#
# A running daemon holds the old code until it is restarted, and nothing
# anywhere says so: the deploy succeeds, the daemon keeps running, and the
# change simply does not take. That is the failure this pins.
#
# How it is tested
# ----------------
# restartFogServices() is EXTRACTED from copybacktrunk.sh and run for real,
# with `systemctl` and `sudo` replaced by stubs on PATH that record what they
# were asked to do. Same approach as test-signed-artifacts-excluded.sh, which
# feeds the real scripts' excludes arrays to a real rsync: the thing under test
# is the shipped code, not a copy of it that can drift.
#
# No webroot, no checkout, no sudo, and nothing is restarted.
#
# Usage: bash test-fog-daemon-restart.sh
# Exit 0 = pass, 1 = fail.

set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$here/CopyBackTrunk/copybacktrunk.sh"

if [[ ! -f $script ]]; then
    echo "FAIL: cannot find $script" >&2
    exit 1
fi

# Pull the function out of the shipped script. Anchored on its own opening and
# on a closing brace in column 1, which is how the file writes it.
fn="$(awk '/^restartFogServices\(\) \{$/,/^\}$/' "$script")"
if [[ -z $fn ]]; then
    echo "FAIL: restartFogServices() not found in copybacktrunk.sh." >&2
    echo "      The deploy no longer restarts the daemons, or it was renamed" >&2
    echo "      and this test now proves nothing." >&2
    exit 1
fi

pass=0
fail=0

# The function existing proves nothing if the deploy never runs it -- deleting
# the call restores the exact bug this file is about, with every assertion
# below still green. Anchored at column 1 so the definition line
# ("restartFogServices() {") and any commented-out or conditionally-guarded
# mention do not satisfy it.
if [[ -z $(grep -c '^restartFogServices$' "$script") ]] \
    || [[ $(grep -c '^restartFogServices$' "$script") -ne 1 ]]; then
    echo "  FAIL  copybacktrunk.sh calls restartFogServices exactly once"
    echo "          the function may exist, but the deploy does not run it"
    fail=$((fail + 1))
else
    echo "  ok    copybacktrunk.sh calls restartFogServices exactly once"
    pass=$((pass + 1))
fi

# Run the extracted function against a stubbed systemd.
#
# $1 is what `systemctl list-units` should report; the stub echoes it verbatim,
# so a test can describe any fleet it likes -- including none. Every sudo call
# is appended to $calls, which is the actual assertion surface.
runWith() {
    local listing="$1"
    # 1 = terminate the listing with a newline, as real systemctl does.
    local terminate="${2:-1}"
    local dir
    dir="$(mktemp -d)"
    calls="$dir/calls"
    : > "$calls"

    # The stub MODELS systemd rather than echoing a canned answer: it holds a
    # fleet with states and honors --state=active. An earlier version ignored
    # its arguments entirely, which meant "only running units are restarted"
    # was asserted by a stub that could not tell the difference.
    cat > "$dir/systemctl" <<STUB
#!/bin/bash
if [[ "\$*" == *list-units* ]]; then
    out=''
    while IFS= read -r line; do
        [[ -z \$line ]] && continue
        if [[ "\$*" == *--state=active* ]]; then
            [[ "\$line" == *" active "* ]] || continue
        fi
        out+="\$line"\$'\n'
    done <<'FLEET'
$listing
FLEET
    # terminate=0 drops only the FINAL newline, so the units stay on separate
    # lines and just the last one is unterminated -- which is the shape being
    # modeled. Dropping every newline would merge them into one line and test
    # something else entirely.
    [[ '$terminate' == 1 ]] || out="\${out%\$'\n'}"
    printf '%s' "\$out"
    exit 0
fi
exit 0
STUB

    cat > "$dir/sudo" <<STUB
#!/bin/bash
echo "\$*" >> "$calls"
exit 0
STUB

    chmod +x "$dir/systemctl" "$dir/sudo"
    out="$(PATH="$dir:$PATH" bash -c "$fn
restartFogServices" 2>&1)"
    rc=$?
    got="$(cat "$calls")"
    rm -rf "$dir"
}

check() {
    if [[ $1 == "$2" ]]; then
        echo "  ok    $3"
        pass=$((pass + 1))
        return
    fi
    echo "  FAIL  $3"
    echo "          expected: [$2]"
    echo "          got:      [$1]"
    fail=$((fail + 1))
}

# The normal case: a full FOG install, everything running.
full='FOGFileDeleter.service loaded active running FOG File Deleter
FOGImageReplicator.service loaded active running FOG Image Replicator
FOGMulticastManager.service loaded active running FOG Multicast Manager'
runWith "$full"
check "$got" \
    "systemctl restart FOGFileDeleter.service FOGImageReplicator.service FOGMulticastManager.service" \
    "every running FOG daemon is restarted, in one call"

# One call, not one per unit: ten sequential restarts is ten windows in which
# the fleet is half old code and half new.
runWith "$full"
check "$(wc -l < <(printf '%s\n' "$got"))" "1" \
    "restarted in a single systemctl invocation"

# A storage node runs a couple of these and not the rest. Whatever systemd
# reports is what gets restarted -- the list is never assumed.
runWith 'FOGImageReplicator.service loaded active running FOG Image Replicator
FOGSnapinReplicator.service loaded active running FOG Snapin Replicator'
check "$got" \
    "systemctl restart FOGImageReplicator.service FOGSnapinReplicator.service" \
    "a partial fleet restarts exactly what is running"

# A daemon FOG has not shipped yet. The list comes from systemd precisely so
# that adding one needs no edit here or in the deploy script.
runWith 'FOGImageReplicator.service loaded active running FOG Image Replicator
FOGSomethingNew.service loaded active running Not Written Yet'
check "$got" \
    "systemctl restart FOGImageReplicator.service FOGSomethingNew.service" \
    "a daemon added later is covered without editing a list"

# A daemon an admin has deliberately stopped. This restarts what is RUNNING;
# it is not a way to start things back up behind someone's back.
runWith 'FOGImageReplicator.service loaded active   running FOG Image Replicator
FOGMulticastManager.service loaded inactive dead    FOG Multicast Manager'
check "$got" \
    "systemctl restart FOGImageReplicator.service" \
    "an inactive daemon is left stopped"

# A listing whose last line has no trailing newline. systemctl terminates its
# output, so this does not arise in production -- but a read loop that silently
# drops its final line is one daemon that never restarts, which is this file's
# entire subject in miniature. It was a real defect, caught on this test's very
# first run, and it stays pinned.
runWith "$full" 0
check "$got" \
    "systemctl restart FOGFileDeleter.service FOGImageReplicator.service FOGMulticastManager.service" \
    "the last unit survives output with no trailing newline"

# Nothing running -- a web-only box, or a first deploy before installfog.sh has
# ever run. Must be silent and must not fail the deploy.
runWith ''
check "$got" "" "no FOG services means nothing is restarted"
check "$rc" "0" "and the deploy does not fail"

echo
if [[ $fail -gt 0 ]]; then
    echo "FAIL ($fail of $((pass + fail)) assertions)"
    exit 1
fi
echo "PASS ($pass assertions)"
