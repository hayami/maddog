#!/bin/sh

color() {
    case "$1" in
    error)   printf '\033[31;1m*** ' ;; # bold red
    warning) printf '\033[31m*** '   ;; # red
    notice)  printf '\033[35m*** '   ;; # violet
    ask)     printf '\033[32m*** '   ;; # green
    esac
    shift
    printf '%s' "$@"
    printf '\033[0m'                    # reset
}

set -e
umask 077

[ -n "$1" ] || (echo "ERROR: $0 requires arugument(s)" 1>&2; exit 1)
cd "$1"

keycomment=${2:-"$USER@console"}

while :; do
    color ask 'Do you want to create ssh key, now? [y/n]: '
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
