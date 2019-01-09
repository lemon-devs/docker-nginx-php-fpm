## Dockerfile

 - Nginx with RTMP support
 - PHP with redis, kafka support

## Build

`docker build name:tag .`

## Run

`docker run -it --name web -p 80:80 -v /data/www/default:/xcdata/www/default -d name:tag`

## Configuration
