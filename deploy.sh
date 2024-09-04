docker image rm mjanaki/php-nginx-alpine-8.0:1.2
docker build --tag mjanaki/php-nginx-alpine-8.0:1.2 .
docker push mjanaki/php-nginx-alpine-8.0:1.2

##intel
docker image rm mjanaki/php80-intl-nginx-alpine:1.0
docker build --platform linux/amd64  --tag mjanaki/php80-intl-nginx-alpine:1.0 .
docker push mjanaki/php80-intl-nginx-alpine:1.0