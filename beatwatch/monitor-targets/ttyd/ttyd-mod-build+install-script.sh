#!/bin/sh

tooldir=${1:-"$HOME/www-tools"}
patchdir=${2:-"$(pwd)"}

### see following URLs for latest releases
###   libuv		https://github.com/libuv/libuv/releases
###   json-c		https://s3.amazonaws.com/json-c_releases/releases/index.html
###   libwebsockets	https://libwebsockets.org/git/libwebsockets/summary
###   ttyd		https://github.com/tsl0922/ttyd/releases
libuv_version='v1.44.2'
jsonc_version='0.16'
libwebsockets_version='v4.3-stable'
ttyd_version='1.7.2'

libuv_download_url=https://dist.libuv.org/dist/${libuv_version}/libuv-${libuv_version}.tar.gz
jsonc_download_url=https://s3.amazonaws.com/json-c_releases/releases/json-c-${jsonc_version}.tar.gz
libwebsockets_git_url=https://libwebsockets.org/repo/libwebsockets
ttyd_download_url=https://github.com/tsl0922/ttyd/archive/refs/tags/${ttyd_version}.tar.gz


umask 022
PATH=/usr/local/bin:/usr/bin:/bin
for x in $(env | sed 's/=.*$//'); do
    case "$x" in
    (HOME|HOSTTYPE|LOGNAME|OSTYPE|PATH|PWD|TERM|TMPDIR|TZ|USER|_) ;;
    (*) unset $x ;;
    esac
done

if [ -z "$TMPDIR"]; then
    TMPDIR=$HOME/tmp
    export TMPDIR
fi
mkdir -p $TMPDIR

set -e
set -x


###
### use gmake if available
###
make=make
if which gmake; then
    make=gmake
fi


###
### create a temporary directory for dependent libraries
###
depdir=$TMPDIR/ttyd-${ttyd_version}-dependencies
rm -rf $depdir
mkdir -p $depdir


###
### check for -ldl
###
use_libdl=0
cd $depdir
cat > libdl-test.c << 'EOF'
#include <dlfcn.h>
int main() { void *handle = 0; dlclose(handle); return 0; }
EOF
if cc libdl-test.c -o libdl-test.o > /dev/null 2>&1; then
    :
else
    if cc libdl-test.c -o libdl-test.o -ldl > /dev/null 2>&1; then
        use_libdl=1
    else
        echo '*** ERROR: can not link with/without -ldl' 1>&2
        exit 1
    fi
fi
echo use_libdl=$use_libdl


###
### build libuv
###
cd $depdir
curl -L -o libuv-${libuv_version}.tar.gz ${libuv_download_url}
tar -xpzf libuv-${libuv_version}.tar.gz
mkdir libuv-${libuv_version}-build libuv-${libuv_version}-root
cd libuv-${libuv_version}-build
cmake \
    -DCMAKE_INSTALL_PREFIX=$depdir/libuv-${libuv_version}-root	\
    -DBUILD_TESTING=OFF						\
    -DCMAKE_BUILD_TYPE=Release					\
    ../libuv-${libuv_version}
cmake --build .
$make install
cd $depdir/libuv-${libuv_version}-root
rm lib/libuv.so.*
rm lib/libuv.so
rm lib/pkgconfig/libuv.pc


###
### build libjson-c
###
mkdir -p $depdir
cd $depdir
curl -L -o json-c-${jsonc_version}.tar.gz ${jsonc_download_url}
tar -xpzf json-c-${jsonc_version}.tar.gz
mkdir json-c-${jsonc_version}-build json-c-${jsonc_version}-root
cd json-c-${jsonc_version}-build
cmake \
    -DCMAKE_INSTALL_PREFIX=$depdir/json-c-${jsonc_version}-root	\
    -DBUILD_SHARED_LIBS=OFF					\
    -DCMAKE_BUILD_TYPE=Release					\
    ../json-c-${jsonc_version}
$make all
$make USE_VALGRIND=0 test
$make install


###
### build libwebsockets
###
mkdir -p $depdir
cd $depdir
rm -rf $HOME/.cmake/packages/libwebsockets
rmdir $HOME/.cmake/packages 2> /dev/null || :
rmdir $HOME/.cmake          2> /dev/null || :
git clone --depth 1			\
    --branch ${libwebsockets_version}	\
    ${libwebsockets_git_url}		\
    libwebsockets-${libwebsockets_version}
[ $use_libdl -eq 0 ] || patch -d libwebsockets-${libwebsockets_version} \
                              -p1 < $patchdir/ttyd-mod-libwebsockets-dl.patch
lwsroot=$depdir/libwebsockets-${libwebsockets_version}-root
luvroot=$depdir/libuv-${libuv_version}-root
mkdir libwebsockets-${libwebsockets_version}-build $lwsroot
cd libwebsockets-${libwebsockets_version}-build
cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=$lwsroot		\
    -DLWS_WITH_SHARED=0					\
    -DLWS_WITH_STATIC=1					\
    -DLWS_WITH_SSL=0					\
    -DLWS_WITH_LIBUV=1					\
    -DLWS_LIBUV_INCLUDE_DIRS=$luvroot/include		\
    -DLWS_LIBUV_LIBRARIES=$luvroot/lib/libuv_a.a	\
    -DCMAKE_BUILD_TYPE=Release				\
    ../libwebsockets-${libwebsockets_version}
$make -v
$make install
rm -rf $HOME/.cmake/packages/libwebsockets
rmdir $HOME/.cmake/packages 2> /dev/null || :
rmdir $HOME/.cmake          2> /dev/null || :


###
### build ttyd (install as ttyd-mod)
###
cd $TMPDIR
rm -f ttyd-${ttyd_version}.tar.gz
rm -rf ttyd-${ttyd_version}
curl -L -o ttyd-${ttyd_version}.tar.gz ${ttyd_download_url}
tar -xpzf ttyd-${ttyd_version}.tar.gz
cd ttyd-${ttyd_version}
for i in $patchdir/ttyd-mod-[0-9]*.patch; do
    patch -p1 < $i
done
[ $use_libdl -eq 0 ] || patch -p1 < $patchdir/ttyd-mod-cap+dl.patch
cd $TMPDIR
rm -rf ttyd-${ttyd_version}-build
mkdir ttyd-${ttyd_version}-build
cd ttyd-${ttyd_version}-build
luvroot=$depdir/libuv-${libuv_version}-root
ljcroot=$depdir/json-c-${jsonc_version}-root
lwsroot=$depdir/libwebsockets-${libwebsockets_version}-root
cmake \
    -DCMAKE_INSTALL_PREFIX=$tooldir ..				\
    -DLIBUV_INCLUDE_DIR=$luvroot/include			\
    -DLIBUV_LIBRARY=$luvroot/lib/libuv_a.a			\
    -DJSON-C_INCLUDE_DIR=$ljcroot/include/json-c		\
    -DJSON-C_LIBRARY=$ljcroot/lib/libjson-c.a			\
    -DLIBWEBSOCKETS_INCLUDE_DIR=$lwsroot/include		\
    -DLIBWEBSOCKETS_LIBRARY=$lwsroot/lib/libwebsockets.a	\
    -DLWS_OPENSSL_ENABLED=0					\
    -DLWS_MBEDTLS_ENABLED=0					\
    -DCMAKE_BUILD_TYPE=Release					\
    ../ttyd-${ttyd_version}
sed -i.sedorig						\
    -e 's|PREFIX}/bin/ttyd"|PREFIX}/bin/ttyd-mod"|'	\
    -e 's|build/ttyd"|build/ttyd" RENAME "ttyd-mod"|'	\
    -e 's|man/ttyd.1"|man/ttyd.1" RENAME "ttyd-mod.1"|'	\
    -e 's| TYPE EXECUTABLE | TYPE PROGRAM |'		\
    cmake_install.cmake
$make
$make install
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
