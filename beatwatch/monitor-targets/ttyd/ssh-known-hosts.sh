#!/bin/sh

set -e
umask 077

[ -n "$1" ] || (echo "ERROR: $0 requires arugument(s)" 1>&2; exit 1)
cd "$1"

sshhost=${2:-localhost}

while :; do
    printf '\033[32m*** '
    printf "Do you want to apped ${sshhost}'s "
    printf 'host key to known_hosts file, now? [y/n]: '
    printf '\033[0m'
    read ans
    case "$ans" in
    [Yy]|[Yy][Ee][Ss])
        break;
        ;;
    [Nn]|[Nn][Oo])
        exit 0
        ;;
    *)
        continue
        ;;
    esac
done

exec ssh $sshhost -o UserKnownHostsFile=known_hosts true
