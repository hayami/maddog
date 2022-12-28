#!/bin/sh

tilde() {
    printf '%s' "$@" | sed -e 's|'"$HOME"'|~|g'
}

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

sshhost=${2:-localhost}

if [ ! -r identity.pub ]; then
    color notice "$(tilde $(pwd)/identity.pub) file not found, skipping."
    echo
    exit 0
fi

if [ $(wc -l < identity.pub) != 1 ]; then
    color error "ERROR: $(tilde $(pwd)/identity.pub) should have only one line."
    echo
    exit 1
fi

case "$sshhost" in
localhost|ip6-localhost)
    break
    ;;
*)
    color notice "You may want to append the $(tilde $(pwd)/identity.pub) " \
        "to ${sshhost}:.ssh/authorized_keys, later."
    echo
    exit 0
    ;;
esac

if [ -r $HOME/.ssh/authorized_keys ]; then
    x=$(diff -u $HOME/.ssh/authorized_keys identity.pub | grep -e '^ ' || :)
    if [ -n "$x" ]; then
        color warning 'Your ~/.ssh/authorized_keys file contains ' \
            'the same line as identity.pub, skipping.'
        echo
        exit 0
    fi
fi

while :; do
    color ask "Do you want to apped $(tilde $(pwd)/identity.pub) to " \
        '~/.ssh/authorized_keys, now? [y/n]: '
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
