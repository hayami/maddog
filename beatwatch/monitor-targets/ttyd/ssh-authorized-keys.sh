#!/bin/sh

tilde() {
    printf "$@" | sed -e 's|'"$HOME"'|~|g'
}

set -e
umask 077

[ -n "$1" ] || (echo "ERROR: $0 requires arugument(s)" 1>&2; exit 1)
cd "$1"

sshhost=${2:-localhost}

if [ ! -r identity.pub ]; then
    printf '*** '
    printf "$(tilde $(pwd)/identity.pub) file not found, skipping."
    printf '\n'
    exit 0
fi

case  "$sshhost" in
localhost|ip6-localhost)
    break
    ;;
*)
    printf '*** '
    printf "You may want to append the $(tilde $(pwd)/identity.pub) to "
    printf "${sshhost}:.ssh/authorized_keys, later."
    printf '\n'
    exit 0
    ;;
esac

if [ -r $HOME/.ssh/authorized_keys ]; then
    x=$(diff -u $HOME/.ssh/authorized_keys identity.pub | grep -e '^ ' || :)
    if [ -n "$x" ]; then
        printf '*** '
        printf 'Your ~/.ssh/authorized_keys file contains '
        printf 'the same line as identity.pub, skipping.'
        printf '\n'
        exit 0
    fi
fi

while :; do
    printf '*** '
    printf "Do you want to apped $(tilde $(pwd)/identity.pub) to "
    printf '~/.ssh/authorized_keys, now? [y/n]: '
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
