#!/bin/sh

umask 022
PATH=/usr/bin:/bin
for x in $(env | sed 's/=.*$//'); do
    case "$x" in
    (HOME|HOSTTYPE|LOGNAME|OSTYPE|PATH|PWD|TERM|TMPDIR|TZ|USER|_) ;;
    (*) unset $x ;;
    esac
done

# ttyd version
v=1.7.2

set -e
set -x
cd $HOME/tmp
rm -f ttyd-$v.tar.gz
rm -rf ttyd-$v
curl -L -o ttyd-$v.tar.gz \
	https://github.com/tsl0922/ttyd/archive/refs/tags/$v.tar.gz
tar -xpzf ttyd-$v.tar.gz
cd ttyd-$v
patch -p0 <<- 'EOF'
	--- src/server.c.orig
	+++ src/server.c
	@@ -572,6 +572,7 @@
	   }
	   int port = lws_get_vhost_listen_port(vhost);
	   lwsl_notice(" Listening on port: %d\n", port);
	+  dprintf(3, "PORT=%d\n", port);
	 
	   if (browser) {
	     char url[30];
	EOF
rm -rf build
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=$HOME/www-tools ..
make
make install
exit 0


# -- INSTALLED FILES --
# $HOME/www-tools/bin/ttyd
# $HOME/www-tools/share/man/man1/ttyd.1


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
