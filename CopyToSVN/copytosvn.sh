#!/bin/bash
#
# copytosvn.sh - pull edits made on a live FOG server back into a git checkout.
#
# Direction: WEB -> GIT. Use this only after editing files directly under the
# webroot. The reverse direction is CopyBackTrunk; running that one afterwards
# will overwrite the webroot from git, so do not chain them.
#
# Usage:
#   copytosvn.sh [repo-path] [webroot]
#
# Both optional, and both also settable as environment variables:
#
#   path        the git checkout   (default: $HOME/fogproject)
#   webroot     the live web tree  (default: from .fogsettings)
#   fogsettings installer settings  (default: /opt/fog/.fogsettings)
#
# WHAT THIS SCRIPT DELIBERATELY NO LONGER DOES
#
# It used to also run php-cs-fixer, regenerate the gettext .pot/.po files, and
# rewrite FOG_VERSION/FOG_CHANNEL. All three now belong to fogproject's
# .githooks/pre-commit, which runs on every commit and does them better:
#
#   * PSR2 fixing there is scoped to the files staged for that one commit, and
#     skips partially-staged files. Doing it here meant running the fixer across
#     the entire live webroot and rsyncing the rewrite into git, which swept
#     unrelated working-tree changes into whatever commit came next.
#   * The version formula lives in .githooks/lib/fog-version.sh and is shared
#     with CI, so a local commit and CI's sweep cannot compute different answers.
#     The copy that used to live here had drifted: it knew 'master' but not
#     'stable' or 'feature-*', and those branches fell through its case and were
#     stamped FOG_CHANNEL='Alpha'.
#
# Keeping them in two places is how they diverge. The hook is the one place.
#
set -u

# Prints dots to a defined set.
# Arguments:
#  $1 The string to pad right the dots.
dots() {
    local string="$1"
    local pad=$(printf "%0.1s" "."{1..60})
    printf " * %s%*.*s" "${string}" 0 $((60-${#string})) "${pad}"
}

# If error sent is not 0 exit from the
#  program and report failed.
# Arguments:
#  $1 The errorcode to test.
errorStat() {
    local error=$1
    if [[ ! $error -eq 0 ]]; then
        echo "Failed"
        exit 1
    fi
    echo "OK"
}

path=${1:-${path:-}}

# Ask the installer where the web tree actually is, rather than assuming
# /var/www/fog -- which is only right for a default single-version install.
#
# Sourced in a SUBSHELL so nothing .fogsettings defines leaks into this
# script's own variables; it sets `webroot` itself under the legacy key
# names, which would otherwise silently overwrite the one being resolved
# here with a bare URL path ("fog") and send the rsync somewhere absurd.
#
# Two generations of key names: GH-1120 renamed all 79 managed keys, so a
# server installed before it carries `docroot`/`webroot` and one installed
# after carries `WEB_docroot`/`WEB_root`. The new name wins where both
# exist, because an upgrade writes it alongside the old one.
fogsettings=${fogsettings:-/opt/fog/.fogsettings}
fogDocroot=""
fogWebroot=""
if [[ -r $fogsettings ]]; then
    eval "$(
        # shellcheck disable=SC1090
        . "$fogsettings" >/dev/null 2>&1
        printf 'fogDocroot=%q\n' "${WEB_docroot:-${docroot:-}}"
        printf 'fogWebroot=%q\n' "${WEB_root:-${webroot:-}}"
    )"
fi

webroot=${2:-${webroot:-}}
if [[ -z $webroot && -n $fogDocroot ]]; then
    webroot="${fogDocroot%/}/${fogWebroot#/}"
    webroot="${webroot%/}"
fi
webroot=${webroot:-/var/www/fog}

[[ -z "$path" || ( ! -e "$path" && ! -e "$HOME/$path" ) ]] && path="$HOME/fogproject"
[[ -e "$HOME/$path" && ! -e "$path" ]] && path="$HOME/$path"

[[ -d "$webroot" ]] || {
    echo "No webroot at ${webroot}."
    exit 1
}
[[ -d "$path/packages/web" ]] || {
    echo "No FOG checkout at ${path} (expected ${path}/packages/web)."
    exit 1
}

# Installer-owned paths that exist ONLY in the deployed tree. Copying them back
# puts installer state and downloaded binaries into the source tree, where they
# do not belong. .gitignore catches most of them, but two are not ignored and
# would show up as untracked files that a `git add -A` sweeps straight into a
# commit:
#
#   service/secureboot/          the published enrolment kit -- MOK.der, the
#                                PK/KEK/db .auth blobs, MokManager.efi. Binary,
#                                and specific to the server it was built on.
#   kea-dhcp4.conf.fog-sample    written by the installer.
#
# The rest are listed anyway rather than relying on .gitignore, so this script
# is correct on its own terms and does not silently depend on a rule in another
# repository staying put. This mirrors CopyBackTrunk's exclude list in reverse.
#
# Patterns are relative to the rsync SOURCE ROOT and quoted so the shell does
# not glob them before rsync sees them.
excludes=(
    # Runtime logs, 0200 and owned by the web user.
    --exclude='fog_*.log'
    # Published Secure Boot enrolment kit.
    --exclude='service/secureboot/'
    # Server certificate issued at install time.
    --exclude='management/other/ssl/'
    # The published CA and its DER form. Gitignored, so they never reach a
    # commit -- but copying them in at all is what leaves one server's CA
    # sitting in the checkout, which CopyBackTrunk would then deploy over a
    # different server's CA while that server keeps its own key.
    --exclude='management/other/ca.cert.*'
    # Generated at deploy time; holds the database credentials.
    --exclude='lib/fog/config.class.php'
    # Written by the installer (GH-850); defines FOG_BASE_DIR.
    --exclude='commons/fogpaths.php'
    # Installer-written sample config.
    --exclude='kea-dhcp4.conf.fog-sample'
    # Compiled translations. The .po sources are tracked; the .mo files are
    # build output and are regenerated on the server.
    --exclude='*.mo'
    # Downloaded FOS binaries, not source -- and the deployed copies are signed
    # for Secure Boot, so copying them into the tree would commit signed
    # artifacts as though they were sources.
    --exclude='service/ipxe/bzImage*'
    --exclude='service/ipxe/init*.xz'
    --exclude='service/ipxe/arm_Image*'
    --exclude='service/ipxe/arm_init.cpio.gz'
    --exclude='service/ipxe/*.sha256'
    --exclude='*.unsigned'
    # The installer's holding page; not part of the application.
    --exclude='maintenance'
    # Editor leftovers.
    --exclude='*~'
)

dots "Copying files to git"
rsync -a --no-links -heP --delete "${excludes[@]}" \
    "${webroot}/" "$path/packages/web" >/dev/null 2>&1
errorStat $?

dots "Cleaning up"
# Belt and braces: --delete plus the excludes above should mean none of these
# arrive, but an older tree may still be carrying them from a previous run.
rm -f "$path/packages/web/lib/fog/config.class.php" >/dev/null 2>&1
rm -rf "$path/packages/web/management/other/cache"/* >/dev/null 2>&1
rm -rf "$path/packages/web/management/other/ssl" >/dev/null 2>&1
rm -f "$path/packages/web/management/other/ca.cert."* >/dev/null 2>&1
find "$path/packages/web/" -type f -name "*~" -delete >/dev/null 2>&1
echo "OK"

echo
echo " * Done. Review with 'git -C ${path} status' before committing."
echo " * The commit hook handles PSR2, the .pot/.po files and the version bump."
exit 0
