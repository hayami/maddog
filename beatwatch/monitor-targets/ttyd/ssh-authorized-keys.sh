#!/bin/sh

tilde() {
    printf '%s' "$@" | sed -e 's|'"$HOME"'|~|g'
}

set -e
umask 077

[ -n "$1" ] || (echo "ERROR: $0 requires arugument(s)" 1>&2; exit 1)
cd "$1"

sshhost=${2:-localhost}

if [ ! -r identity.pub ]; then
    printf '\033[32m*** '
    printf '%s' "$(tilde $(pwd)/identity.pub) file not found, skipping."
    printf '\033[0m\n'
    exit 0
fi

case "$sshhost" in
localhost|ip6-localhost)
    break
    ;;
*)
    printf '\033[32m*** '
    printf '%s' "You may want to append the $(tilde $(pwd)/identity.pub) to "
    printf '%s' "${sshhost}:.ssh/authorized_keys, later."
    printf '\033[0m\n'
    exit 0
    ;;
esac

if [ -r $HOME/.ssh/authorized_keys ]; then
    x=$(diff -u $HOME/.ssh/authorized_keys identity.pub | grep -e '^ ' || :)
    if [ -n "$x" ]; then
        printf '\033[32m*** '
        printf '%s' 'Your ~/.ssh/authorized_keys file contains '
        printf '%s' 'the same line as identity.pub, skipping.'
        printf '\033[0m\n'
        exit 0
    fi
fi

while :; do
    printf '\033[32m*** '
    printf '%s' "Do you want to apped $(tilde $(pwd)/identity.pub) to "
    printf '%s' '~/.ssh/authorized_keys, now? [y/n]: '
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

cat identity.pub >> $HOME/.ssh/authorized_keys
chmod go-rwxst $HOME/.ssh/authorized_keys
exit 0
