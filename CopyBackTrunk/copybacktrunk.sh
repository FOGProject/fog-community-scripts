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
fogIp=""
fogProto=""
if [[ -r $fogsettings ]]; then
    eval "$(
        # shellcheck disable=SC1090
        . "$fogsettings" >/dev/null 2>&1
        printf 'fogEngine=%q\n' "${WEB_server_engine:-${webserver:-}}"
        printf 'fogDocroot=%q\n' "${WEB_docroot:-${docroot:-}}"
        printf 'fogWebroot=%q\n' "${WEB_root:-${webroot:-}}"
        printf 'fogIp=%q\n' "${NET_fog_server_ip:-${ipaddress:-}}"
        printf 'fogProto=%q\n' "${WEB_url_proto:-}"
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
    # Same story for the agent CA bundle (fogproject feat/agent-enroll): the
    # installer publishes it next to ca.cert.pem and Agent\Principal verifies
    # every agent certificate against it. Deleting it turns every poll into a
    # 401 and the agents throw their certificates away and re-enroll.
    --exclude='management/other/agent-ca-bundle.pem'
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
    # rEFInd, and this is the direction that BREAKS BOOTING. Unlike the
    # kernels above these ARE tracked, so the checkout genuinely has a copy to
    # deploy -- carrying only the upstream signature. installfog.sh
    # countersigns the deployed ones with the server's own Secure Boot key, so
    # syncing the repo copy over a signed one strips that countersignature and
    # Secure Boot clients stop booting with nothing on the server to explain
    # why. Re-run installfog.sh to update and re-sign these.
    --exclude='service/ipxe/refind*.efi'
    # Memtest86+ (fogproject #321): tracked upstream binaries that installfog.sh
    # countersigns in place with the kernels, so the same rule as refind*.efi.
    --exclude='service/ipxe/mt86plus_*'
    # Installer-downloaded ESP archives; gitignored, so the checkout has
    # nothing to deploy and syncing would only delete the server's.
    --exclude='service/localboot/'
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
# Wrong destination is not a visible failure either way. If nothing is left at
# the path the tree actually reads, FOG boots to `Class "Config" not found` --
# a fatal before any output, i.e. a blank page with nothing in the browser to
# say why.
if [[ -d $path/packages/web/src ]]; then
    configdest="commons/config.class.php"
    configstale="lib/fog/config.class.php"
else
    configdest="lib/fog/config.class.php"
    configstale="commons/config.class.php"
fi
sudo install -d "$(dirname "${webroot}/${configdest}")"
sudo cp "$configpath" "${webroot}/${configdest}"

# Retire the copy at the other path, if a previous deploy left one.
#
# The excludes above protect BOTH spellings, and an rsync exclude is protected
# from --delete as well as from transfer -- so a webroot first deployed when
# the config lived at the other path keeps that file forever, even though the
# source tree no longer has the directory at all. Verified: with lib/fog/
# absent from the source, --delete removes an unexcluded sibling and leaves
# the excluded config standing.
#
# Two files then declare class Config inside a scanned root. Initiator's
# collision rule picks one by scan order and error_log()s the other, so this
# is not a fatal -- it is worse than a fatal. FOG boots either way, off
# whichever copy the scan happened to reach first, and the losing file is a
# generated credential store (the DB password, both FTP passwords, the schema
# token) sitting in the webroot at a path nothing maintains.
#
# Guarded on the destination existing, so a failed cp above cannot leave the
# tree with no config at all.
if [[ -e ${webroot}/${configstale} && -s ${webroot}/${configdest} ]]; then
    echo "Removing superseded ${configstale} (config now lives at ${configdest})"
    sudo rm -f "${webroot}/${configstale}"
    sudo rmdir --ignore-fail-on-non-empty "$(dirname "${webroot}/${configstale}")" 2>/dev/null
fi
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

# Restart the FOG daemons for the same reason the web services are restarted
# above: they are running the code this script just replaced.
#
# This did not used to matter. The daemons' entry points live in
# /opt/fog/service, which this script does not deploy, and until the PSR-4 move
# each one carried its own copy of the service loop -- so a webroot deploy
# genuinely did not change what a running daemon executed. It does now: the
# entry points are three-line stubs and the loop itself is
# packages/web/src/Service/, which is inside the tree rsynced above. A running
# daemon holds the OLD code until it is restarted, so a deploy that changes
# daemon behavior looks like a deploy that did nothing at all.
#
# There is no per-daemon subset worth working out. All ten boot the same core
# through commons/base.inc.php -- src/Base, src/Db, src/Router -- so almost any
# PHP file in the tree can change what any of them does, which is exactly why
# the web services above are restarted unconditionally rather than diffed.
#
# WHAT THIS COSTS: an in-flight replication transfer or multicast session is
# killed and picked up again on the daemon's next pass. installfog.sh has
# always restarted these unconditionally, so this is not new behavior for a
# server -- it is new for this script, which people run far more often.
restartFogServices() {
    local units=()
    # Enumerated from systemd rather than hardcoded, so a daemon added to FOG
    # later is covered here without anyone remembering to edit a list -- which
    # is the failure this whole change exists to stop.
    #
    # --state=active means a unit an admin has deliberately stopped stays
    # stopped: this restarts what is running, it does not start what is not.
    # `|| [[ -n $unit ]]` so a final line with no trailing newline is still
    # read: without it `read` returns non-zero on that line and the loop drops
    # the last daemon, which is the one-daemon-never-restarted bug in miniature.
    # systemctl does terminate its output, but a loop that only works because
    # its input is well behaved is a loop waiting to be fed by something else.
    while read -r unit _ || [[ -n ${unit:-} ]]; do
        [[ -n $unit ]] && units+=("$unit")
        unit=''
    done < <(
        systemctl list-units --type=service --state=active --no-legend 'FOG*' \
            2>/dev/null
    )

    if [[ ${#units[@]} -eq 0 ]]; then
        return 0
    fi

    echo "  restarting ${#units[@]} FOG service(s) to load the deployed code"
    # Reported rather than swallowed. A daemon that fails to come back leaves
    # imaging silently broken, and this script has no `set -e` to catch it.
    if ! sudo systemctl restart "${units[@]}"; then
        echo "  !! one or more FOG services failed to restart" >&2
        return 1
    fi
    return 0
}

restartFogServices

# Bring the DATABASE up to the code we just deployed.
#
# WHY THIS IS HERE AT ALL. FOG_SCHEMA is a constant in the deployed tree, and
# DatabaseManager sends every request to the schema updater while the
# database's stored version is below it. So deploying a checkout that carries
# a new schema step does not merely leave a step unapplied -- it takes the
# whole UI out, every page, until somebody logs in and clicks Install/Update.
# The deploy looks like it succeeded and the server looks broken, which is a
# bad half hour if you did not connect the two. Observed 2026-09-06 doing
# exactly that.
#
# This is the same channel installfog.sh uses (updateDB() in
# lib/common/functions.sh): a POST carrying X-Fog-Install-Token, which is the
# one way to run a schema deploy without a logged-in session. That function
# cannot simply be called from here -- it lives in the other repository and
# expects several dozen installer variables to be set -- so the essential
# part is reproduced, and only that part.
#
# TWO DELIBERATE DIFFERENCES FROM THE INSTALLER'S VERSION:
#
# It dials the loopback with --resolve rather than resolving the server's
# name for real. The installer had to stop passing -k because doing so handed
# the install token to whoever answered on that address; pinning the name to
# 127.0.0.1 answers the same objection more directly, since the thing that
# answers is then this machine by construction, while still verifying the
# certificate properly. A deploy script is always talking to its own box.
#
# It will CREATE the token if the install predates it. Servers installed
# before the token existed have no FOG_SCHEMA_INSTALL_TOKEN line at all, and
# on those the automatic path is simply shut -- which is the state this box
# was in. The constant is written to $configpath, the SOURCE config, not to
# the copy in the webroot: the deploy above overwrites the webroot copy from
# that file on every run, so a token written only to the webroot would be
# generated fresh every time and never match anything.
#
# Set schemaupdate=0 to skip all of this. It is on by default for the same
# reason the installer's is: leaving the database behind the code is not a
# safe default, it is just a quieter failure.
deploySchema() {
    [[ ${schemaupdate:-1} == 0 ]] && return 0

    local root=${fogWebroot:-/fog/}
    local page="${root}management/index.php"

    # WHICH ADDRESS, AND WHY NOT THE LOOPBACK. FOG's nginx binds :80 on
    # 0.0.0.0 but :443 only on the real interfaces, so on a TLS install
    # https://127.0.0.1/ is refused while http://127.0.0.1/ answers -- with
    # whatever default vhost that machine has, which is not FOG. A probe
    # that tried loopback first therefore chose the wrong scheme AND the
    # wrong server, and got a 404 back from something that had never heard
    # of FOG. The installer's own record of the address is the right source;
    # loopback stays only as a last resort for an install that wrote none.
    # The addresses actually bound by a web server on this box, newest
    # source of truth first. This is deliberately not read from the
    # installer's settings file: the key holding the address has been
    # renamed at least once, an install predating the rename has the old
    # one, and a wrong guess here silently produces an empty address and a
    # fall back to loopback -- which is exactly the failure above. What
    # ports 443 and 80 are bound to cannot be out of date.
    #
    # 443 before 80 because a TLS install redirects 80 to 443 anyway, and a
    # wildcard bind (0.0.0.0 / ::) is rewritten to loopback, which is a real
    # address to dial rather than one to connect to.
    local addrs=() a
    while read -r a; do
        a=${a%:*}
        a=${a#\[}; a=${a%\]}
        case $a in
            '0.0.0.0'|'*'|'::'|'') a=127.0.0.1 ;;
        esac
        [[ " ${addrs[*]} " == *" $a "* ]] || addrs+=("$a")
    done < <(
        ss -lnt 2>/dev/null \
            | awk '$4 ~ /:443$/ {print $4}
                   $4 ~ /:80$/  {print $4}'
    )
    [[ -n ${fogIp:-} ]] && [[ " ${addrs[*]} " != *" $fogIp "* ]] && addrs+=("$fogIp")
    [[ ${#addrs[@]} -eq 0 ]] && addrs=(127.0.0.1)

    # REACHING SOMETHING IS NOT REACHING FOG. A candidate qualifies only if
    # this page answers 2xx after redirects; a 404 means we are talking to
    # some other vhost and the answer must not be believed. The first
    # version of this accepted any status that was not 000, read a 404 as
    # "no redirect to the schema updater", and cheerfully reported the
    # database as current while the UI was in fact locked to the updater.
    local addr proto base landing code curlopts=()
    schemaLanding() {
        landing=$(curl -s -o /dev/null -w '%{http_code} %{url_effective}' -L \
            "${curlopts[@]}" "${base}${page}" 2>/dev/null)
        code=${landing%% *}
    }

    local found=0
    for addr in "${addrs[@]}"; do
        for proto in https http; do
            curlopts=(--noproxy '*' --max-time 60)
            base="${proto}://${addr}"
            if [[ $proto == https ]]; then
                # Address the server by the name its certificate carries,
                # read off the certificate actually being served -- what
                # _servedCertName() does in the installer, and for the same
                # reason: dialling an address verifies only by luck, since a
                # leaf from a public CA cannot carry an IP SAN at all.
                #
                # --resolve pins that name to the address already chosen, so
                # the name verifies properly while the machine answering is
                # still this one by construction. That is the objection the
                # installer met by dropping -k -- passing -k handed the
                # install token to whoever answered -- met more directly.
                local name
                name=$(echo \
                    | openssl s_client -connect "${addr}:443" 2>/dev/null \
                    | openssl x509 -noout -subject -nameopt RFC2253 2>/dev/null \
                    | sed -n 's/.*CN=\([^,]*\).*/\1/p')
                [[ -z $name ]] && continue
                curlopts+=(--resolve "${name}:443:${addr}")
                base="https://${name}"
                if [[ -r ${webroot}/management/other/ca.cert.pem ]]; then
                    curlopts+=(--cacert "${webroot}/management/other/ca.cert.pem")
                else
                    curlopts+=(-k)
                fi
            fi
            schemaLanding
            if [[ $code == 2* ]]; then found=1; break 2; fi
        done
    done

    # FAILS CLOSED. Every way of not reaching FOG -- wrong scheme, wrong
    # address, a certificate that will not verify, another vhost answering
    # -- has to report a problem, never a pass. A check that cannot run is
    # not a check that succeeded.
    if [[ $found -ne 1 ]]; then
        echo "  !! schema: could not reach FOG on ${addrs[*]} to check the database." >&2
        echo "     The deployed code may be ahead of the schema, which locks the UI" >&2
        echo "     to the updater. Check it at ${page}" >&2
        return 1
    fi

    # While the database is behind, FOG sends every request to node=schema;
    # once it is current the page stops going there. No credential and no
    # database access needed, and it is the exact symptom this prevents.
    if [[ $landing != *node=schema* ]]; then
        echo "  schema: database already matches the deployed code"
        return 0
    fi

    # The token. Reused if the install has one, created if it does not.
    #
    # grep -q, never a read of the value into a variable that could be
    # echoed: this file is the generated credential store and holds the
    # database password and both FTP passwords as well.
    if ! sudo grep -q "FOG_SCHEMA_INSTALL_TOKEN" "$configpath" 2>/dev/null; then
        echo "  schema: this install predates FOG_SCHEMA_INSTALL_TOKEN; generating one"
        # WRITTEN BY PHP, NOT APPENDED BY THE SHELL. The first version of
        # this used `tee -a` with its own <?php line, which opens a second
        # tag inside a file already in PHP mode: instant parse error, and
        # since this file is what FOG loads first, the whole install went
        # down until it was undone. So: PHP decides where the statement can
        # legally go, the original is kept, and php -l has to pass before
        # the result is allowed to stand.
        if ! sudo php -r '
                $f = $argv[1];
                $src = file_get_contents($f);
                copy($f, $f . ".cbtbak");
                $line = "\nif (!defined(\"FOG_SCHEMA_INSTALL_TOKEN\")) {\n"
                    . "    define(\"FOG_SCHEMA_INSTALL_TOKEN\", \""
                    . bin2hex(random_bytes(32)) . "\");\n}\n";
                // A file left in PHP mode takes the statement at the end; one
                // that closed its tag takes it just before the close.
                $t = rtrim($src);
                if (substr($t, -2) === "?>") {
                    $out = substr($t, 0, -2) . $line . "?>\n";
                } else {
                    $out = $t . "\n" . $line;
                }
                file_put_contents($f, $out);
                exit(0);
            ' "$configpath"; then
            echo "  !! schema: could not write the install token" >&2
            return 1
        fi
        # The gate. A config that does not parse is a dead server, so this
        # is checked and rolled back rather than hoped about.
        if ! sudo php -l "$configpath" >/dev/null 2>&1; then
            echo "  !! schema: writing the token broke ${configpath}; restoring it" >&2
            sudo mv -f "${configpath}.cbtbak" "$configpath"
            return 1
        fi
        sudo rm -f "${configpath}.cbtbak"
        # The webroot copy was taken from $configpath before the token
        # existed, so refresh it or this run has no token to present.
        sudo cp "$configpath" "${webroot}/${configdest}"
        sudo chown "${webuser}":"${webgroup}" "${webroot}/${configdest}"
    fi

    echo "  schema: deploying the database schema"
    # The token is read by PHP out of the config and handed to curl through
    # an environment variable, so the secret never appears in a command line
    # that ps or the shell history can see.
    if ! FOG_TOKEN=$(sudo php -r '
            require $argv[1];
            echo defined("FOG_SCHEMA_INSTALL_TOKEN") ? FOG_SCHEMA_INSTALL_TOKEN : "";
        ' "${webroot}/${configdest}" 2>/dev/null) || [[ -z $FOG_TOKEN ]]; then
        echo "  !! schema: could not read the install token; deploy the schema in the UI" >&2
        echo "     ${base}${page}" >&2
        return 1
    fi
    curl -X POST -H "X-Fog-Install-Token: ${FOG_TOKEN}" -d "schemaupdate=1" \
        "${curlopts[@]}" -fsL "${base}${page}?node=schema" -o /dev/null
    local rc=$?
    unset FOG_TOKEN

    # Verified by asking again, not by trusting curl's exit status: a 200
    # from the updater page is not the same claim as "the schema is current".
    schemaLanding
    if [[ $landing == *node=schema* || $landing == 000\ * || -z $landing ]]; then
        echo "  !! schema: the database is still behind the deployed code (curl $rc)." >&2
        echo "     Deploy it in the UI: ${base}${page}" >&2
        return 1
    fi
    echo "  schema: database updated"
    return 0
}

deploySchema

exit 0
