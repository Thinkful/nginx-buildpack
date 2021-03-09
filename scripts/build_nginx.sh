#!/bin/bash
# Build NGINX and modules on Heroku.

# This program is designed to run during the
# application build process.
# We would like to build an NGINX binary for the buildpack on the
# exact machine in which the binary will run.

NGINX_VERSION=1.16.1
PCRE_VERSION=8.41
HEADERS_MORE_VERSION=0.33

INSTALL_ROOT=$1

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=https://downloads.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2
headers_more_nginx_module_url=https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

echo "Downloading $pcre_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvj )

echo "Downloading $headers_more_nginx_module_url"
(cd nginx-${NGINX_VERSION} && curl -L $headers_more_nginx_module_url | tar xvz )

echo "Starting build..."

if [ $DEBUG -eq 1 ];then
    DESTDIR=/opt/nginx
    INSTALL_ROOT=""
fi

(
	cd nginx-${NGINX_VERSION}
	./configure \
		--with-pcre=pcre-${PCRE_VERSION} \
		--with-http_ssl_module \
		--prefix=${INSTALL_ROOT} \
		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION} \
		--with-http_realip_module \
		--with-http_stub_status_module
	make install
)

if [ $DEBUG -eq 1 ];then
(
	cd $temp_dir/nginx-${NGINX_VERSION}
	./configure \
		--with-pcre=pcre-${PCRE_VERSION} \
		--with-http_ssl_module \
		--prefix=${INSTALL_ROOT} \
		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION} \
		--with-http_realip_module \
		--with-http_stub_status_module \
        --with-debug
	make install DESTDIR=/opt/nginx-debug
)

fi

echo "Build completed successfully."
