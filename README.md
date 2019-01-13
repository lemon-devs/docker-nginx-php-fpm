## Dockerfile

 - Nginx 1.15.8
 - PHP 7.3.1 with redis, kafka support

## Build

`docker build name:tag .`

## Run

`docker run -it --name web -p 80:80 -v /data/www/default:/xcdata/www/default -d name:tag`
