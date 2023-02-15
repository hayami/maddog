#!/bin/sh
set -e
umask 077

host='https://miranda.tok.access-company.com'
basepath='/~hayami/tty/ttyd/ssh/-'

# unset env
PATH=/usr/bin:/bin
for x in $(env | sed 's/=.*$//'); do
    case "$x" in
    (HOME|PATH|PWD|TMPDIR|TZ|USER)               ;;
    (AUTH_TYPE|CONTEXT_*|DOCUMENT_ROOT)          ;;
    (GATEWAY_INTERFACE|HTTPS|HTTP_|QUERY_STRING) ;;
    (REMOTE_*|REQUEST_*|SCRIPT_*|SERVER_*|SSL_*) ;;
    (*) unset $x ;;
    esac
done

# set HOME
export HOME=${HOME:-$(eval echo '~'"$(id -u -n)")}
case "$HOME" in
/*)
    [ -d "$HOME" ] || exit 1
    [ -w "$HOME" ] || exit 1
    ;;
*)  exit 1
    ;;
esac

# set PATH
export PATH=$HOME/www-tools/bin:$PATH

# set TMPDIR
export TMPDIR=${TMPDIR:-"$HOME/tmp"}
[ -d "$TMPDIR" ] || exit 1
[ -w "$TMPDIR" ] || exit 1

# set scriptdir
real_script_path=$(realpath --canonicalize-existing ${SCRIPT_FILENAME:-"$0"})
scriptdir=$(dirname "$real_script_path")

# set prefixstr
base=$(basename "$real_script_path")
prefixstr=${base%.*}		# remove any suffix starting with '.'

# Check .disable
if [ -f $scriptdir/$prefixstr.disable ]; then
    printf 'Content-Type: text/html\r\n'
    printf '\r\n'
    printf '<!DOCTYPE html>'
    printf '<html>'
    printf '<head><title>The script is now disabled</title></head>'
    printf '<body><p>The script is now disabled.</p></body>'
    printf '</html>'
    printf '\r\n'
    exit 0
fi

# set rundir, then cd to there
#   The $rundir should only be removed if the beatwatch exits successfully.
#   Otherwise, this directory should be left untouched for later analysis.
cd $TMPDIR
rundir=$TMPDIR/$(mktemp -d "${prefixstr}-XXXXXXXX")
cd $rundir

# source .shfunc
. $scriptdir/$prefixstr.shfunc 

# unset most env
for x in $(env | sed 's/=.*$//'); do
    case "$x" in
    (HOME|PATH|PWD|TMPDIR|TZ|USER) ;;
    (*) unset $x ;;
    esac
done

# Copy ssh related files to $rundir/ssh
cp -prL $HOME/www-tools/etc/ttyd/ssh .

# Store command and arguments in $@
cmdargs "$rundir" "$basepath" > cmdargs.txt
set --; while read line; do set -- "$@" "$line"; done < cmdargs.txt

# The loop to start the command starts here
(env "$@" 3>&1 2> stderr.log 1> stdout.log < /dev/null &) | while read line; do
    case "$line" in
    PORT=[0-9]*)
        echo ${line#'PORT='} > port
        url="${host}${basepath}/"'?port='"$(cat port)"

        echo 'Content-Type: text/html'
        echo
        echo '<!DOCTYPE html>'
        echo '<html>'
        echo '<body>'
        echo '<a href="'"$url"'">'"$url"'</a>'
        echo '</body>'
        echo '</html>'
        break
        ;;
    *)
        ;;
    esac
done

exit 0
