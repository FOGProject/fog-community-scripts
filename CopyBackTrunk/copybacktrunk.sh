#!/bin/bash
#
# copybacktrunk.sh - deploy a FOG git checkout's web tree to the live webroot.
#
# Direction: GIT -> WEB. Use this after editing in the repository to test the
# change on a running server. The reverse direction is CopyToSVN.
#
# Usage:
#   copybacktrunk.sh [repo-path] [config-path] [version-suffix]
#
# All three are optional and can also be supplied as environment variables:
#
#   path        the git checkout                 (default: $HOME/fogproject)
#   configpath  config.class.php to install      (default: /opt/fog/config.class.php)
#   ver         webroot version suffix, or empty (default: empty)
#   webroot     destination document root        (default: from .fogsettings)
#   webuser     owner of the deployed tree       (default: from .fogsettings)
#   webgroup    group of the deployed tree       (default: same as webuser)
#   fogsettings the installer's settings file    (default: /opt/fog/.fogsettings)
#   devmode     1 to keep the tree editable by   (default: unset)
#               the invoking user
#   devgroup    group given write access by      (default: invoking user's
#               devmode                           primary group)
#
# DEVMODE exists for the one workflow this script's sibling is built around:
# editing files directly under the webroot and pulling them back with
# CopyToSVN. After a normal deploy the tree is owned by the web user with
# the repository's own modes, so those edits need sudo -- which is correct
# for a server and useless on a development box.
#
# It grants GROUP write to a named group, rather than the `chmod -R 777`
# that development copies of this script have historically carried. 777
# means every account on the box can rewrite the code the web server
# executes; this means one group can.
#
# The version suffix exists for servers that keep several trees side by side
# (/var/www/html/fog-1.5, fog-1.6, ...) and symlink the live one. Leave it unset
# for an ordinary single-version install and nothing is symlinked.
#
set -u

path=${1:-${path:-}}
configpath=${2:-${configpath:-}}
ver=${3:-${ver:-}}

[[ -z "$path" || ( ! -e "$path" && ! -e "$HOME/$path" ) ]] && path="$HOME/fogproject"
[[ -e "$HOME/$path" && ! -e "$path" ]] && path="$HOME/$path"

# Ask the installer what this server actually runs, rather than guessing.
#
# .fogsettings is the record of the install, and it is SOURCED here the same
# way installfog.sh sources it -- in a subshell, so nothing it defines leaks
# into this script's own variables and overwrites an explicit override.
#
# Two generations of key names. GH-1120 renamed all 79 managed keys to
# CATEGORY_lower_snake_case, so a server installed before that carries
# `webserver`/`docroot`/`webroot` and one installed after carries
# `WEB_server_engine`/`WEB_docroot`/`WEB_root`. An upgrade migrates the old
# to the new, but "has been upgraded since" is not something a deploy script
# can assume, so both are read and the new name wins.
fogsettings=${fogsettings:-/opt/fog/.fogsettings}
fogEngine=""
fogDocroot=""
fogWebroot=""
if [[ -r $fogsettings ]]; then
    eval "$(
        # shellcheck disable=SC1090
        . "$fogsettings" >/dev/null 2>&1
        printf 'fogEngine=%q\n' "${WEB_server_engine:-${webserver:-}}"
        printf 'fogDocroot=%q\n' "${WEB_docroot:-${docroot:-}}"
        printf 'fogWebroot=%q\n' "${WEB_root:-${webroot:-}}"
    )"
fi

# The web user is NOT stored in .fogsettings -- the installer derives it per
# distro from the engine, so this has to derive it the same way. The old
# guess here was "nginx if that user exists, else apache", which is wrong on
# every Debian/Ubuntu box running Apache (www-data) and every Arch box
# running Apache (http): the deploy then chowned the whole webroot to a user
# the web server is not, and every page 403s until somebody chowns it back.
#
# Resolved by taking the first candidate that actually EXISTS on this
# machine, so an unusual build lands somewhere real rather than on a name
# nobody has. Mirrors lib/{redhat,ubuntu,arch,alpine}/config.sh.
if [[ -z ${webuser:-} ]]; then
    case ${fogEngine,,} in
        apache|httpd|apache2)
            candidates=(apache www-data http)
            ;;
        nginx)
            candidates=(nginx http www-data)
            ;;
        *)
            # No engine recorded (a very old install, or an unreadable
            # .fogsettings). Fall back to what is running rather than to a
            # hardcoded name.
            if systemctl is-active --quiet nginx 2>/dev/null; then
                candidates=(nginx http www-data)
            else
                candidates=(apache www-data http nginx)
            fi
            ;;
    esac
    for candidate in "${candidates[@]}"; do
        if id -u "$candidate" >/dev/null 2>&1; then
            webuser=$candidate
            break
        fi
    done
fi
if [[ -z ${webuser:-} ]]; then
    echo "Could not work out the web user. Set webuser= and re-run." >&2
    exit 1
fi
webgroup=${webgroup:-$webuser}

# With a version suffix the tree lives beside its siblings and /var/www/html/fog
# points at whichever is current; without one it is just the webroot.
if [[ -n $ver ]]; then
    webroot=${webroot:-/var/www/html/fog-${ver}}
    weblink=${weblink:-/var/www/html/fog}
else
    # $fogDocroot is the document root the installer wrote (e.g.
    # /var/www/html/) and $fogWebroot the URL path under it (e.g. fog), so
    # the deployed tree is the two joined. Falling back to /var/www/fog
    # keeps the old behaviour for a server with no readable .fogsettings.
    if [[ -z ${webroot:-} && -n $fogDocroot ]]; then
        webroot="${fogDocroot%/}/${fogWebroot#/}"
        webroot="${webroot%/}"
    fi
    webroot=${webroot:-/var/www/fog}
    weblink=""
fi

# config.class.php is generated at install time and is NOT in git, so it has to
# be kept outside the checkout and copied back in after every deploy.
if [[ -z $configpath ]]; then
    if [[ -n $ver && -e /opt/fog/config-${ver}.class.php ]]; then
        configpath="/opt/fog/config-${ver}.class.php"
    else
        configpath="/opt/fog/config.class.php"
    fi
fi
[[ ! -e $configpath ]] && {
    echo "No configuration file available. Please make sure this file exists: ${configpath}"
    exit 1
}

# Installer-owned paths under the webroot. These are NOT in packages/web, so
# --delete removes them on every run; and the ones that DO exist in both get the
# repo's copy written over the installer's. Either way a code deploy quietly
# undoes installer state, so exclude them.
#
# Patterns are relative to the rsync SOURCE ROOT and quoted so the shell does
# not glob them first. An --exclude given as an absolute path
# ($path/packages/web/fog_*.log) is one rsync can never match -- and unquoted,
# a glob that did expand would have turned the extra matches into additional
# rsync SOURCE arguments.
excludes=(
    # Runtime logs, 0200 and owned by the web user.
    --exclude='fog_*.log'
    # MOK enrolment kit, published by the installer's _publishSecureBootKit.
    # Deleting it is what makes the Secure Boot page fall back to "not
    # configured on this server" after a deploy.
    --exclude='service/secureboot/'
    # Server certificate issued at install time.
    --exclude='management/other/ssl/'
    # The published CA and its DER form, which the web server hands to clients
    # through an explicit RewriteRule. Both are gitignored, so a clean checkout
    # has no copy of them and --delete would remove the deployed ones: client
    # CA enrolment then 404s and srvchained.crt loses its anchor. A checkout
    # that HAS them is worse -- an old CopyToSVN run left one server's CA in
    # the tree, and deploying that tree elsewhere publishes the wrong CA while
    # the target keeps its own key.
    --exclude='management/other/ca.cert.*'
    # Generated at deploy time and re-copied below. Both spellings, because
    # this one script deploys 1.5 and 1.6 and the file moved: 1.6 generates it
    # into commons/, beside fogpaths.php, after lib/fog/ was retired -- that
    # directory held nothing else once core became PSR-4 under src/. Excluding
    # a path the tree does not have costs nothing, so both are listed rather
    # than branched on.
    --exclude='lib/fog/config.class.php'
    --exclude='commons/config.class.php'
    # Generated by the installer (GH-850); defines FOG_BASE_DIR, which
    # commons/init.php loads before the autoloader. Deleting it is a fatal
    # undefined-constant on every page, and it is what FOGPage's
    # secureBootStagingDir()/fog-sign-kernel lookup resolves against.
    --exclude='commons/fogpaths.php'
    # Installer-written sample config.
    --exclude='kea-dhcp4.conf.fog-sample'
    # Compiled translations: gitignored, so they exist only in the deployed
    # tree. Deleting them silently drops every non-English UI string.
    --exclude='*.mo'
    # Downloaded FOS binaries, not source. The DEPLOYED copies are signed for
    # Secure Boot and the repo copies are not, so syncing these reverts the
    # kernels to unsigned -- Secure Boot clients then stop booting with nothing
    # on the server to explain why. Re-run installfog.sh to update kernels.
    --exclude='service/ipxe/bzImage*'
    --exclude='service/ipxe/init*.xz'
    --exclude='service/ipxe/arm_Image*'
    --exclude='service/ipxe/arm_init.cpio.gz'
    # _resignKernels' pre-signature snapshots of the above.
    --exclude='*.unsigned'
)

# Point a symlink at the versioned tree, whatever is sitting there now.
#
# This used to be `rm -f` followed by `ln -sf`, which breaks in one specific
# way and then keeps breaking:
#
#   `rm` without -r CANNOT remove a directory (-f only suppresses the
#   error). `ln -sf` with a DIRECTORY as its link name does not replace it
#   either -- it creates the link INSIDE it, as fog/fog-1.6. Both commands
#   "succeed", the deploy prints nothing unusual, and the web server then
#   404s every page because <docroot>/fog/management/index.php no longer
#   exists.
#
#   It is self-perpetuating: once the directory exists every later deploy
#   repeats the same two no-ops, and PHP running under the broken root
#   recreates management/logs/ underneath it, so it never becomes empty.
#
# -n on `ln` is not enough on its own: it stops ln descending into a link
# that POINTS at a directory, not into a real one. So the stale path is
# dealt with explicitly first.
#
# A real directory is MOVED ASIDE rather than deleted. It should only ever
# hold stray logs, but "should only ever" is not a good enough reason to
# rm -rf something under a web root while nobody is watching.
linkVersioned() {
    local target="$1"
    local link="$2"

    if [[ -L $link ]]; then
        sudo rm -f "$link"
    elif [[ -d $link ]]; then
        local aside="${link}.stale-$(date +%Y%m%d%H%M%S)"
        echo "  ! ${link} is a directory, not a symlink -- moving it to ${aside}"
        sudo mv "$link" "$aside"
    elif [[ -e $link ]]; then
        sudo rm -f "$link"
    fi

    sudo ln -sfn "$target" "$link"

    # Verified rather than assumed. The whole point is that the failure this
    # replaces was silent.
    if [[ "$(readlink "$link")" != "$target" ]]; then
        echo "  !! failed to link ${link} -> ${target}" >&2
        return 1
    fi
}

sudo rsync -a --no-links -heP --delete "${excludes[@]}" \
    "$path/packages/web/" "$webroot"

# Not shipped to a live server; it is the installer's holding page.
sudo rm -rf "${webroot}/maintenance"

# Where the generated config goes in the tree being deployed.
#
# Probed from the CHECKOUT, not from $ver. $ver is a filename suffix the caller
# passes to pick which template to install; it says nothing about the layout of
# the tree actually being rsynced, and getting those two out of step writes the
# config somewhere nothing reads. packages/web/src/ exists only on the PSR-4
# branches, which are exactly the ones that generate into commons/.
#
# Wrong destination is not a visible failure. The rsync --delete has already
# removed whatever was at the other path, so FOG boots to
# `Class "Config" not found` -- a fatal before any output, i.e. a blank page.
if [[ -d $path/packages/web/src ]]; then
    configdest="commons/config.class.php"
else
    configdest="lib/fog/config.class.php"
fi
sudo install -d "$(dirname "${webroot}/${configdest}")"
sudo cp "$configpath" "${webroot}/${configdest}"
sudo chown -R "${webuser}":"${webgroup}" "$webroot"
sudo chown -R fogproject:"${webgroup}" "${webroot}/service/ipxe"

# Logs are write-only for the web user; the rsync above restores repo modes on
# anything it did copy, so reassert it here.
sudo chmod 0200 "${webroot}"/fog_*.log 2>/dev/null

# Development boxes only, and opt-in. See DEVMODE in the header.
#
# Ordered after the chowns deliberately: those set the web user as OWNER,
# and this only widens the GROUP, so the web server's own access is
# untouched either way. The logs above keep their 0200 -- they are excluded
# here because making a write-only log group-writable is not what anyone
# means by "let me edit the code".
if [[ ${devmode:-} == 1 ]]; then
    devgroup=${devgroup:-$(id -gn)}
    echo "  devmode: granting ${devgroup} write access to ${webroot}"
    sudo chgrp -R "$devgroup" "$webroot"
    sudo find "$webroot" -name 'fog_*.log' -prune -o -exec chmod g+w {} +
fi

# Multi-version layout only: point /var/www/html/fog at this tree, and give the
# tree a self-referential "fog" link so a URL of /fog/fog/... still resolves.
if [[ -n $weblink ]]; then
    linkVersioned "$webroot" "$weblink"
    linkVersioned "$webroot" "${webroot}/fog"
fi

# Reload so opcache does not keep serving the previous copy of changed files.
for svc in nginx httpd apache2 php-fpm; do
    systemctl is-active --quiet "$svc" 2>/dev/null && sudo systemctl restart "$svc"
done

exit 0
