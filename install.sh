#!/bin/sh
# sensor installer — https://sensor.filamentplatform.com
#
# This script does as little as possible on purpose. It downloads the signed
# .deb from GitHub Releases and hands it to apt; apt owns the install, which
# is what lets `sudo apt purge sensor` reverse every change later.
#
# Read it before running it. That is the point of a script you pipe to a shell:
#   curl -fsSL https://sensor.filamentplatform.com/install.sh | less

set -eu

REPO="Filament-Platform-Inc/Sensor"
API="https://api.github.com/repos/$REPO/releases/latest"

red()  { printf '\033[31m%s\033[0m\n' "$1" >&2; }
info() { printf '  %s\n' "$1"; }

die() { red "error: $1"; exit 1; }

# --- checks ---------------------------------------------------------------

[ "$(id -u)" -ne 0 ] || die "run this as your normal user, not root.
       It calls sudo itself, and needs to know who to grant device access to."

command -v apt-get >/dev/null 2>&1 \
  || die "this installer needs apt (Debian or Ubuntu).
       Other distributions: build from source at https://github.com/$REPO"

case "$(uname -m)" in
  x86_64|amd64) ;;
  *) die "sensor currently ships for x86-64 only, not $(uname -m).
       Build from source at https://github.com/$REPO" ;;
esac

command -v curl >/dev/null 2>&1 || die "curl is required"

# --- what this will do ----------------------------------------------------

cat <<BANNER

  sensor — voice dictation for Linux

  This will:
    1. download the latest .deb from github.com/$REPO
    2. install it with apt (you will be asked for your password)
    3. add you to the 'input' and 'uinput' groups, so it can read your
       hotkey and type for you

  Everything is installed by apt, so 'sudo apt purge sensor' removes all
  of it later — including the group changes.

BANNER

# --- download -------------------------------------------------------------

info "finding the latest release..."
URL=$(curl -fsSL "$API" \
  | grep -o '"browser_download_url": *"[^"]*_amd64\.deb"' \
  | head -n1 \
  | cut -d'"' -f4)

[ -n "${URL:-}" ] || die "could not find a .deb in the latest release.
       Download it manually: https://github.com/$REPO/releases/latest"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT INT TERM
DEB="$TMP/sensor.deb"

info "downloading $(basename "$URL")"
curl -fL --progress-bar -o "$DEB" "$URL" || die "download failed"

# A truncated download would fail later in a more confusing way.
dpkg-deb --info "$DEB" >/dev/null 2>&1 \
  || die "the downloaded file is not a valid package"

# --- install --------------------------------------------------------------

echo
info "installing (sudo will ask for your password)"
# Quiet: apt's dependency chatter buries the instructions that follow, and
# the errors we care about still reach stderr.
if ! sudo apt-get install -y -qq "$DEB" >/dev/null; then
  die "apt could not install the package.
       Try manually: sudo apt install $DEB"
fi

# --- next steps -----------------------------------------------------------

cat <<'DONE'

  Installed.

  Two things left:

    1. Run:  sensorctl setup
       Downloads the speech model (~75MB, once) and enables the daemon.

    2. Log out and back in.
       Your group list is fixed when a session starts, so this one cannot
       see the 'input' and 'uinput' groups you were just added to. One
       logout, once. It is the price of the daemon running as you rather
       than as root.

  Then hold Right Alt + . , speak, and release.
  Open "sensor" from your applications to change the key or turn it off.

DONE
