FROM centos:7
LABEL maintainer "YumeMichi <do4suki@gmail.com>"

# Main
RUN rm -rf /etc/yum.repos.d/* \
    && curl http://mirrors.aliyun.com/repo/Centos-7.repo > /etc/yum.repos.d/CentOS-Base.repo \
    && curl http://mirrors.aliyun.com/repo/epel-7.repo > /etc/yum.repos.d/epel.repo \
    && yum makecache \
    && yum install -y gcc gcc-c++ make wget unzip autoconf \
    && useradd -s /sbin/nologin www \
    && yum install -y pcre pcre-devel zlib zlib-devel libxml2 libxml2-devel openssl openssl-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel libmcrypt libmcrypt-devel readline readline-devel freetype freetype-devel net-tools \
    && mkdir ~/phpdir && cd ~/phpdir \
    && wget -O php-5.6.39.tar.gz http://101.96.10.64/cn2.php.net/distributions/php-5.6.39.tar.gz \
    && tar xf php-5.6.39.tar.gz && cd php-5.6.39 \
    && ./configure --prefix=/xcdata/server/php --with-config-file-path=/xcdata/server/php/etc --enable-inline-optimization --enable-sockets --enable-bcmath --enable-zip --enable-mbstring --enable-opcache --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-curl --with-mysql --with-mysqli --with-pdo-mysql --with-readline --with-zlib --with-gd --with-xmlrpc --with-mcrypt --with-openssl --with-freetype-dir --with-jpeg-dir --with-png-dir --disable-ipv6 --disable-debug --disable-maintainer-zts --disable-fileinfo \
    && make -j24 && make install \
    && cp php.ini-production /xcdata/server/php/etc/php.ini \
    && cp /xcdata/server/php/etc/php-fpm.conf.default /xcdata/server/php/etc/php-fpm.conf \
    && yum install -y librdkafka librdkafka-devel \
    && cd ~/phpdir/php-5.6.39/ext && wget -O php-rdkafka.zip https://github.com/arnaud-lb/php-rdkafka/archive/master.zip  \
    && unzip php-rdkafka.zip && cd php-rdkafka-master && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config \
    && make -j24 && make install && echo "extension = rdkafka.so" >> /xcdata/server/php/etc/php.ini \
    && cd ~/phpdir/php-5.6.39/ext && wget -O php-redis.zip https://github.com/phpredis/phpredis/archive/develop.zip \
    && unzip php-redis.zip && cd phpredis-develop && /xcdata/server/php/bin/phpize \
    && ./configure --with-php-config=/xcdata/server/php/bin/php-config \
    && make -j24 && make install && echo "extension = redis.so" >> /xcdata/server/php/etc/php.ini \
    && cd ~/phpdir && wget http://nginx.org/download/nginx-1.15.8.tar.gz \
    && tar xf nginx-1.15.8.tar.gz && cd ~/phpdir/nginx-1.15.8 \
    && mkdir -p /var/tmp/nginx/{client,proxy,fastcgi,uwsgi,scgi} && mkdir -p /var/run/nginx \
    && ./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/tmp/nginx/client --http-proxy-temp-path=/var/tmp/nginx/proxy --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi --http-scgi-temp-path=/var/tmp/nginx/scgi --user=www --group=www --with-file-aio --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --with-http_random_index_module --with-http_degradation_module --with-http_slice_module --with-file-aio --with-http_v2_module --with-ld-opt=-lrt --with-pcre --with-pcre-jit \
    && make -j24 && make install \
    && mkdir -p /xcdata/server/nginx/vhosts \
    && mkdir -p /xcdata/www/default \
    && rm -rf ~/phpdir \
    && yum clean all

# Configs
COPY res/nginx.conf /etc/nginx
COPY res/default.conf /xcdata/server/nginx/vhosts
COPY res/index.php /xcdata/www/default

# Setup PATH
ENV PATH="$PATH:/xcdata/server/php/bin:/xcdata/server/php/sbin"

# Port
EXPOSE 80
EXPOSE 443

# Workdir
WORKDIR /xcdata/www

# Entrypoint
COPY res/docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
