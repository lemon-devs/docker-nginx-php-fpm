## Dockerfile

 - Nginx 1.17.8
 - PHP 7.4.3 with redis, kafka and swoole support

## Build

`docker build name:tag .`

## Run

`docker run -it --name web -p 80:80 -v /data/www/default:/xcdata/www/default -d name:tag`
