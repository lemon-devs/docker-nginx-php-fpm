FROM centos:7
LABEL maintainer "YumeMichi <do4suki@gmail.com>"

# env
ENV BISON_VER 3.8.2
ENV LIBZIP_VER 1.8.0
ENV PHP_VER 7.4.25
ENV RDKAFKA_VER 5.0.0
ENV SWOOLE_VER 4.8.2
ENV REDIS_VER 5.3.4
ENV NGINX_VER 1.20.2

# yum
RUN rm -rf /etc/yum.repos.d/* && sed -i 's|enabled=1|enabled=0|g' /etc/yum/pluginconf.d/fastestmirror.conf \
    && curl http://mirrors.163.com/.help/CentOS7-Base-163.repo > /etc/yum.repos.d/CentOS-Base.repo \
    && curl http://mirrors.aliyun.com/repo/epel-7.repo > /etc/yum.repos.d/epel.repo \
    && yum makecache && yum update -y \
    && useradd -s /sbin/nologin www \
    && mkdir ~/phpdir

# rpm
RUN yum install -y gcc gcc-c++ make wget unzip autoconf cmake cmake3 file \
    && yum install -y pcre pcre-devel zlib zlib-devel libxml2 libxml2-devel openssl openssl-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel libmcrypt libmcrypt-devel readline readline-devel freetype freetype-devel bzip2 bzip2-devel oniguruma oniguruma-devel sqlite sqlite-devel postgresql postgresql-devel

# proxychains
RUN cd ~/phpdir \
    && wget -O proxychains-ng.zip https://github.com/rofl0r/proxychains-ng/archive/master.zip \
    && unzip proxychains-ng.zip && cd proxychains-ng-master \
    && ./configure && make -j24 && make install \
    && cp ./src/proxychains.conf /etc/proxychains.conf \
    && sed -i '$d' /etc/proxychains.conf && sed -i '$d' /etc/proxychains.conf \
    && sed -i '$d' /etc/proxychains.conf && sed -i '$d' /etc/proxychains.conf \
    && echo "socks5 172.17.0.1 1080" >> /etc/proxychains.conf

# bison
RUN cd ~/phpdir \
    && wget -O bison.tar.gz http://ftp.gnu.org/gnu/bison/bison-${BISON_VER}.tar.gz \
    && tar xf bison.tar.gz && cd bison-${BISON_VER} \
    && ./configure && make -j24 && make install

# libzip
RUN cd ~/phpdir \
    && wget -O libzip.tar.gz https://libzip.org/download/libzip-${LIBZIP_VER}.tar.gz \
    && tar xf libzip.tar.gz && cd libzip-${LIBZIP_VER} \
    && mkdir build && cd build && cmake3 .. && make -j24 && make install \
    && echo -e "/usr/local/lib\n/usr/local/lib64\n/usr/lib\n/usr/lib64" >> /etc/ld.so.conf && ldconfig -v

# php
RUN cd ~/phpdir \
    && wget -O php.tar.gz https://www.php.net/distributions/php-${PHP_VER}.tar.gz \
    && tar xf php.tar.gz && cd php-${PHP_VER} \
    && ./configure --prefix=/xcdata/server/php --with-config-file-path=/xcdata/server/php/etc --enable-inline-optimization --enable-sockets --enable-bcmath --enable-zip --enable-mbstring --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-curl --with-mysqli --with-pdo-mysql --enable-mysqlnd --with-readline --with-zlib --enable-gd --with-xmlrpc --with-openssl --with-freetype --with-jpeg --with-pdo-pgsql --with-pgsql --disable-ipv6 --disable-debug --disable-maintainer-zts --disable-fileinfo \
    && make -j24 && make install \
    && cp php.ini-production /xcdata/server/php/etc/php.ini \
    && cp /xcdata/server/php/etc/php-fpm.conf.default /xcdata/server/php/etc/php-fpm.conf \
    && mv /xcdata/server/php/etc/php-fpm.d/www.conf.default /xcdata/server/php/etc/php-fpm.d/www.conf

# exts
## php-rdkafka
RUN yum install -y librdkafka librdkafka-devel \
    && cd ~/phpdir/php-${PHP_VER}/ext \
    && wget -O php-rdkafka.tar.gz https://github.com/arnaud-lb/php-rdkafka/archive/${RDKAFKA_VER}.tar.gz  \
    && tar xf php-rdkafka.tar.gz && cd php-rdkafka-${RDKAFKA_VER} \
    && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config \
    && make -j24 && make install && echo "extension = rdkafka.so" >> /xcdata/server/php/etc/php.ini

## php-swoole
RUN cd ~/phpdir/php-${PHP_VER}/ext \
    && wget -O swoole-src.tar.gz https://github.com/swoole/swoole-src/archive/v${SWOOLE_VER}.tar.gz  \
    && tar xf swoole-src.tar.gz && cd swoole-src-${SWOOLE_VER} \
    && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config --enable-coroutine --enable-openssl --enable-http2 --enable-async-redis --enable-sockets --enable-mysqlnd \
    && make -j24 && make install && echo "extension = swoole.so" >> /xcdata/server/php/etc/php.ini

## php-redis
RUN cd ~/phpdir/php-${PHP_VER}/ext \
    && wget -O phpredis.tar.gz https://github.com/phpredis/phpredis/archive/${REDIS_VER}.tar.gz \
    && tar xf phpredis.tar.gz && cd phpredis-${REDIS_VER} \
    && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config \
    && make -j24 && make install && echo "extension = redis.so" >> /xcdata/server/php/etc/php.ini

## php-zbarcode
RUN cd ~/phpdir/php-${PHP_VER}/ext \
    && yum install -y ImageMagick ImageMagick-devel \
    && wget -O zbar.tar.gz https://newcontinuum.dl.sourceforge.net/project/zbar/zbar/0.10/zbar-0.10.tar.gz \
    && tar xf zbar.tar.gz && cd zbar-0.10 \
    && ./configure --prefix=/usr/local/zbar --without-gtk --without-python --without-qt --disable-video \
    && make -j24 && make install && ldconfig -v \
    && ln -s /usr/local/zbar/lib/pkgconfig/zbar.pc /usr/lib64/pkgconfig/zbar.pc \
    && cd ~/phpdir/php-${PHP_VER}/ext \
    && wget -O php-zbarcode.zip https://github.com/YumeMichi/php-zbarcode/archive/refs/heads/master.zip \
    && unzip php-zbarcode.zip && cd php-zbarcode-master && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config \
    && make -j24 && make install && echo "extension = zbarcode.so" >> /xcdata/server/php/etc/php.ini

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
