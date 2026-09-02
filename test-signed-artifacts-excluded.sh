#!/bin/bash
#
# Pins that neither sync direction moves a Secure Boot signed artifact.
#
# Why this exists
# ---------------
# installfog.sh countersigns the deployed kernels and rEFInd binaries with the
# server's OWN Secure Boot key. The tracked copies carry only the upstream
# signature. So the two directions fail differently and both fail quietly:
#
#   web -> git   pulls a locally-countersigned binary into the checkout, where
#                committing it publishes one server's signing key's output as
#                though it were the upstream source. refind*.efi is TRACKED,
#                so this is a real content change to a committed file, not an
#                ignored stray -- `git status` shows "M", nothing else does.
#
#   git -> web   deploys the repo copy over the signed one, stripping the
#                countersignature. Secure Boot clients then stop booting, with
#                nothing on the server to say why.
#
# This was not hypothetical: on 2026-08-27 a web -> git run pulled all four
# refind*.efi into the fogproject checkout, each carrying a second signature
# from "CN=FOG Project Secure Boot Signing". The kernels were already excluded
# in both scripts; rEFInd never was.
#
# Both excludes arrays are extracted from their scripts and fed to a REAL
# rsync. No webroot, no checkout, no sudo.
#
# Usage: bash test-signed-artifacts-excluded.sh
# Exit 0 = pass, 1 = fail.

set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

failures=0
note() { echo "FAIL: $*"; failures=$((failures + 1)); }

# Artifacts installfog.sh signs or downloads, which must not cross in either
# direction, and one file that must still cross so an over-broad exclude is
# caught.
signed=(
    service/ipxe/refind.efi
    service/ipxe/refind_x64.efi
    service/ipxe/refind_ia32.efi
    service/ipxe/refind_aa64.efi
    service/ipxe/bzImage
    service/ipxe/bzImage32
    service/ipxe/init.xz
    service/ipxe/mt86plus_x86_64
    service/ipxe/mt86plus_i586
    service/localboot/fog-esp-x86_64.zip
)
must_cross=(
    service/ipxe/refind.conf
    management/index.php
    service/Pre_Stage1.php
)

check_direction() {
    local label=$1 script=$2
    local arr=$work/$label.excludes.sh
    local src=$work/$label/src dst=$work/$label/dst

    sed -n '/^excludes=(/,/^)$/p' "$here/$script" > "$arr"
    grep -q "service/ipxe/bzImage" "$arr" \
        || { note "$label: excludes array not found in $script"; return; }

    rm -rf "$work/$label"
    mkdir -p "$src" "$dst"
    local rel
    for rel in "${signed[@]}" "${must_cross[@]}"; do
        mkdir -p "$src/$(dirname "$rel")"
        echo "content of $rel" > "$src/$rel"
    done

    (
        # shellcheck disable=SC1090
        source "$arr"
        rsync -a --no-links --delete "${excludes[@]}" "$src/" "$dst"
    ) >/dev/null 2>&1 || note "$label: rsync exited non-zero"

    for rel in "${signed[@]}"; do
        [[ -e $dst/$rel ]] && note "$label: $rel crossed -- a signed or downloaded artifact was synced"
    done
    for rel in "${must_cross[@]}"; do
        [[ -e $dst/$rel ]] || note "$label: $rel did NOT cross -- an exclude is too broad"
    done
}

check_direction web-to-git CopyToSVN/copytosvn.sh
check_direction git-to-web CopyBackTrunk/copybacktrunk.sh

if [[ $failures -gt 0 ]]; then
    echo "$failures failure(s)"
    exit 1
fi
echo "signed-artifacts: ${#signed[@]} artifacts held back in both directions,"
echo "                  ${#must_cross[@]} real files still cross"
echo "PASS"
exit 0
