#!/bin/sh

tooldir=${1:-"$HOME/www-tools"}
patchdir=${2:-"$(pwd)"}

umask 022
PATH=/usr/bin:/bin
for x in $(env | sed 's/=.*$//'); do
    case "$x" in
    (HOME|HOSTTYPE|LOGNAME|OSTYPE|PATH|PWD|TERM|TMPDIR|TZ|USER|_) ;;
    (*) unset $x ;;
    esac
done

if [ -z "$TMPDIR"]; then
    mkdir -p $HOME/tmp
    TMPDIR=$HOME/tmp
    export TMPDIR
fi

# ttyd version
v=1.7.2

set -e
set -x
cd $TMPDIR
rm -f ttyd-$v.tar.gz
rm -rf ttyd-$v
curl -L -o ttyd-$v.tar.gz \
    https://github.com/tsl0922/ttyd/archive/refs/tags/$v.tar.gz
tar -xpzf ttyd-$v.tar.gz
cd ttyd-$v
for i in $patchdir/ttyd-mod-src-[0-9]*.patch; do
    patch -p0 < $i
done
rm -rf build
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$tooldir ..
cat $patchdir/ttyd-mod-cmake-install.patch	\
    | sed -e "s|%%%|$TMPDIR/ttyd-$v|g"		\
    | patch -p0
make
make install
exit 0


# -- INSTALLED FILES --
# $HOME/www-tools/bin/ttyd-mod
# $HOME/www-tools/share/man/man1/ttyd-mod.1


# MEMO:
#   The (Debian) control has the following build dependencies:
#	|Build-Depends:
#	| cmake,
#	| debhelper-compat (= 13),
#	| libjson-c-dev,
#	| libwebsockets-dev,
#	| zlib1g-dev,
#
#   The command on the next line installs the following packages:
#	$ sudo apt-get install cmake libjson-c-dev libwebsockets-dev zlib1g-dev
#	| cmake, cmake-data, libcap-dev, libev-dev, libev4,
#	| libjson-c-dev, libjsoncpp1, librhash0, libuv1-dev,
#	| libwebsockets-dev, libwebsockets15, zlib1g-dev
#
#   Debian (or Ubuntu) seems to use the following options:
#	|# /etc/default/ttyd
#	|
#	|TTYD_OPTIONS="-i lo -p 7681 -O login"
