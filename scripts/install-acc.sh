#!/usr/bin/env bash
# Install (or upgrade) ACC on a rooted Android phone over adb, and optionally the AccA app.
#
# Usage:  scripts/install-acc.sh [-s SERIAL] [--apk]
#   -s SERIAL   adb device serial (required when more than one device is connected)
#   --apk       also install dist/AccA-*.apk (adb install -r)
#
# Runs from Git Bash on Windows, or any POSIX shell with adb on PATH.
set -euo pipefail

# Git Bash rewrites /data/... arguments into Windows paths unless this is set.
export MSYS_NO_PATHCONV=1

here="$(cd "$(dirname "$0")/.." && pwd)"
serial=""
with_apk=false
while [ $# -gt 0 ]; do
  case "$1" in
    -s) serial="$2"; shift 2;;
    --apk) with_apk=true; shift;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
adb_() { if [ -n "$serial" ]; then adb -s "$serial" "$@"; else adb "$@"; fi; }

tgz="$(ls "$here"/dist/acc_*.tgz | tail -1)"
installer="$here/acc/install-tarball.sh"

# The staging dir must NOT match /data/local/tmp/acc[-_]*: ACC's uninstall.sh (run by the
# installer to remove the previous version) deletes that glob, taking the tarball with it.
stage=/data/local/tmp/staging_acc_install

adb_ shell su -c id | grep -q 'uid=0' || { echo "no root (su) on the device" >&2; exit 1; }

adb_ shell "rm -rf $stage; mkdir -p $stage"
adb_ push "$tgz" "$stage/$(basename "$tgz")"
adb_ push "$installer" "$stage/install-tarball.sh"
adb_ shell "su -c 'cd $stage && sh install-tarball.sh acc'"
adb_ shell "rm -rf $stage"

if $with_apk; then
  adb_ install -r "$(ls "$here"/dist/AccA-*.apk | tail -1)"
fi

echo
echo "Installed:"
adb_ shell "su -c '/dev/acc -v; pgrep -f accd.sh >/dev/null && echo accd running || echo accd NOT running'"
