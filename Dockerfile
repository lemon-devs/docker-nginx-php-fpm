FROM centos:7
LABEL maintainer "YumeMichi <do4suki@gmail.com>"

# Setup YUM
RUN rm -rf /etc/yum.repos.d/* && \
    curl http://mirrors.aliyun.com/repo/Centos-7.repo > /etc/yum.repos.d/CentOS-Base.repo && \
    curl http://mirrors.aliyun.com/repo/epel-7.repo > /etc/yum.repos.d/epel.repo && \
    yum makecache

# Preparations
RUN yum install -y gcc gcc-c++ make && \
    useradd -s /sbin/nologin www && \
    yum install -y pcre pcre-devel zlib zlib-devel libxml2 libxml2-devel openssl openssl-devel libcurl libcurl-devel libpng libpng-devel libmcrypt libmcrypt-devel readline readline-devel freetype freetype-devel net-tools

# Build PHP
RUN mkdir ~/phpdir && cd ~/phpdir && \
    curl http://cn2.php.net/get/php-5.6.38.tar.gz/from/this/mirror > php-5.6.38.tar.gz && \
    tar xf php-5.6.38.tar.gz && cd php-5.6.38 && \
    ./configure --prefix=/xcdata/server/php --with-config-file-path=/xcdata/server/php/etc --enable-inline-optimization --enable-sockets --enable-bcmath --enable-zip --enable-mbstring --enable-opcache --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-curl --with-mysql --with-mysqli --with-pdo-mysql --with-readline --with-zlib --with-gd --with-xmlrpc --with-mcrypt --with-openssl --with-freetype-dir --with-jpeg-dir --with-png-dir --disable-ipv6 --disable-debug --disable-maintainer-zts --disable-fileinfo && \
    make && make install && \
    cp php.ini-production /xcdata/server/php/etc/php.ini && \
    cp /xcdata/server/php/etc/php-fpm.conf.default /xcdata/server/php/etc/php-fpm.conf && \
    cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && \
    chmod +x /etc/init.d/php-fpm

# Install Nginx
COPY res/nginx /etc/init.d/nginx
COPY res/nginx.conf /etc/nginx
COPY res/default.conf /xcdata/server/nginx/vhosts
COPY res/index.php /xcdata/www/default
RUN yum install -y nginx && \
    chmod +x /etc/init.d/nginx && \
    mkdir -p /xcdata/server/nginx/vhosts && \
    mkdir -p /xcdata/www/default

# Start services
RUN /etc/init.d/php-fpm start && \
    /etc/init.d/nginx start && \
    echo "/etc/init.d/nginx start" >> /etc/rc.local && \
    echo "/etc/init.d/php-fpm start" >> /etc/rc.local

# Setup PATH
ENV PATH="$PATH:/xcdata/server/php/bin:/xcdata/server/php/sbin"

EXPOSE 80

WORKDIR /xcdata/www

# CMD [ "nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf" ]
# CMD [ "php-fpm", "--nodaemonize", "--fpm-config", "/xcdata/server/php/etc/php-fpm.conf", "--pid", "/xcdata/server/php/var/run/php-fpm.pid" ]

# Entrypoint
COPY res/docker-entrypoint.sh /
ENTRYPOINT [ "/docker-entrypoint.sh" ]
