FROM centos:7
LABEL maintainer "YumeMichi <do4suki@gmail.com>"

# Version
ENV LIBZIP_VER 1.5.2
ENV PHP_VER 7.4.0
ENV RDKAFKA_VER 4.0.0
ENV SWOOLE_VER 4.4.12
ENV SWOOLE_ASYNC_VER 4.4.12
ENV REDIS_VER 5.1.1
ENV NGINX_VER 1.17.6

# Preparing
RUN rm -rf /etc/yum.repos.d/* && sed -i 's|enabled=1|enabled=0|g' /etc/yum/pluginconf.d/fastestmirror.conf \
    && curl http://mirrors.163.com/.help/CentOS7-Base-163.repo > /etc/yum.repos.d/CentOS-Base.repo \
    && yum install -y epel-release \
    && yum makecache \
    && useradd -s /sbin/nologin www \
    && mkdir ~/phpdir

# Dependencies
RUN yum install -y gcc gcc-c++ make wget unzip autoconf cmake cmake3 \
    && yum install -y pcre pcre-devel zlib zlib-devel libxml2 libxml2-devel openssl openssl-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel libmcrypt libmcrypt-devel readline readline-devel freetype freetype-devel bzip2 bzip2-devel oniguruma oniguruma-devel sqlite sqlite-devel

# libzip
RUN cd ~/phpdir \
    && wget -O libzip.tar.gz https://libzip.org/download/libzip-${LIBZIP_VER}.tar.gz \
    && tar xf libzip.tar.gz && cd libzip-${LIBZIP_VER} \
    && mkdir build && cd build && cmake3 .. && make -j24 && make install \
    && echo -e "/usr/local/lib\n/usr/local/lib64\n/usr/lib\n/usr/lib64" >> /etc/ld.so.conf && ldconfig -v

# PHP
RUN cd ~/phpdir \
    && wget -O php.tar.gz https://www.php.net/distributions/php-${PHP_VER}.tar.gz \
    && tar xf php.tar.gz && cd php-${PHP_VER} \
    && ./configure --prefix=/xcdata/server/php --with-config-file-path=/xcdata/server/php/etc --enable-inline-optimization --enable-sockets --enable-bcmath --enable-zip --enable-mbstring --enable-opcache --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-curl --with-mysqli --with-pdo-mysql --with-readline --with-zlib --with-gd --with-xmlrpc --with-openssl --with-freetype-dir --with-jpeg-dir --with-png-dir --disable-ipv6 --disable-debug --disable-maintainer-zts --disable-fileinfo \
    && make -j24 && make install \
    && cp php.ini-production /xcdata/server/php/etc/php.ini \
    && cp /xcdata/server/php/etc/php-fpm.conf.default /xcdata/server/php/etc/php-fpm.conf \
    && mv /xcdata/server/php/etc/php-fpm.d/www.conf.default /xcdata/server/php/etc/php-fpm.d/www.conf

# Extensions
## rdkafka
RUN yum install -y librdkafka librdkafka-devel \
    && cd ~/phpdir/php-${PHP_VER}/ext \
    && wget -O php-rdkafka.tar.gz https://github.com/arnaud-lb/php-rdkafka/archive/${RDKAFKA_VER}.tar.gz  \
    && tar xf php-rdkafka.tar.gz && cd php-rdkafka-${RDKAFKA_VER} \
    && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config \
    && make -j24 && make install && echo "extension = rdkafka.so" >> /xcdata/server/php/etc/php.ini

## swoole
RUN cd ~/phpdir/php-${PHP_VER}/ext \
    && wget -O swoole-src.tar.gz https://github.com/swoole/swoole-src/archive/v${SWOOLE_VER}.tar.gz  \
    && tar xf swoole-src.tar.gz && cd swoole-src-${SWOOLE_VER} \
    && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config --enable-coroutine --enable-openssl --enable-http2 --enable-async-redis --enable-sockets --enable-mysqlnd \
    && make -j24 && make install && echo "extension = swoole.so" >> /xcdata/server/php/etc/php.ini

## swoole_async
RUN cd ~/phpdir/php-${PHP_VER}/ext \
    && wget -O ext-async.tar.gz https://github.com/swoole/ext-async/archive/v${SWOOLE_ASYNC_VER}.tar.gz  \
    && tar xf ext-async.tar.gz && cd ext-async-${SWOOLE_ASYNC_VER} \
    && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config \
    && make -j24 && make install && echo "extension = swoole_async.so" >> /xcdata/server/php/etc/php.ini

## redis
RUN cd ~/phpdir/php-${PHP_VER}/ext \
    && wget -O phpredis.tar.gz https://github.com/phpredis/phpredis/archive/${REDIS_VER}.tar.gz \
    && tar xf phpredis.tar.gz && cd phpredis-${REDIS_VER} \
    && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config \
    && make -j24 && make install && echo "extension = redis.so" >> /xcdata/server/php/etc/php.ini

# Nginx
RUN cd ~/phpdir \
    && wget -O nginx.tar.gz http://nginx.org/download/nginx-${NGINX_VER}.tar.gz \
    && tar xf nginx.tar.gz && cd nginx-${NGINX_VER} \
    && mkdir -p /var/tmp/nginx/{client,proxy,fastcgi,uwsgi,scgi} && mkdir -p /var/run/nginx \
    && ./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/tmp/nginx/client --http-proxy-temp-path=/var/tmp/nginx/proxy --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi --http-scgi-temp-path=/var/tmp/nginx/scgi --user=www --group=www --with-file-aio --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-http_random_index_module --with-http_degradation_module --with-http_slice_module --with-file-aio --with-http_v2_module --with-ld-opt=-lrt --with-pcre --with-pcre-jit \
    && make -j24 && make install \
    && mkdir -p /xcdata/server/nginx/vhosts \
    && mkdir -p /xcdata/www/default

COPY res/nginx.conf /etc/nginx
COPY res/default.conf /xcdata/server/nginx/vhosts
COPY res/index.php /xcdata/www/default

# Cleanup
RUN rm -rf ~/phpdir \
    && yum clean all \
    && rm -rf /var/cache/yum

# PATH
ENV PATH="$PATH:/xcdata/server/php/bin:/xcdata/server/php/sbin"

# Port
EXPOSE 80
EXPOSE 443

# Workdir
WORKDIR /xcdata/www

# Entrypoint
COPY res/docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
