## Dockerfile

 - Nginx 1.20.1
 - PHP 5.6 with security updates merged in

## Build

`docker build name:tag .`

## Run

`docker run -it --name web -p 80:80 -v /data/www/default:/xcdata/www/default -d name:tag`
