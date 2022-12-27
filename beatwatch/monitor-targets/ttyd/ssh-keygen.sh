#!/bin/sh

set -e
umask 077

[ -n "$1" ] || (echo "ERROR: $0 requires arugument(s)" 1>&2; exit 1)
cd "$1"

keycomment=${2:-"$USER@console"}

while :; do
    printf '\033[32m*** '
    printf '%s' 'Do you want to create ssh key, now? [y/n]: '
    printf '\033[0m'
    read ans
    case "$ans" in
    [Yy]|[Yy][Ee][Ss])
        break
        ;;
    [Nn]|[Nn][Oo])
        exit 0
        ;;
    *)
        continue
        ;;
    esac
done

exec ssh-keygen -b 4096 -f identity -C "$keycomment"
