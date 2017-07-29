FROM debian:jessie

ENV MODSECURITY_VERSION 2.9.2
ENV NGINX_VERSION 1.13.3

# Dependencies
RUN apt-get update --fix-missing
RUN apt-get install -y git wget curl build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev libcurl4-openssl-dev automake pkgconf

# Modsecurity
RUN wget -O /opt/modsecurity.tar.gz https://github.com/SpiderLabs/ModSecurity/releases/download/v${MODSECURITY_VERSION}/modsecurity-${MODSECURITY_VERSION}.tar.gz
RUN cd /opt/ && tar xvf /opt/modsecurity.tar.gz && \
    cd /opt/modsecurity-${MODSECURITY_VERSION}/ && \
    ./autogen.sh && \
    ./configure --enable-standalone-module && \
    make

# Nginx
RUN wget -O /opt/nginx.tar.gz http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
RUN cd /opt/ && tar xvf nginx.tar.gz && \
    cd /opt/nginx-${NGINX_VERSION} && \
    ./configure --user=www-data --group=www-data --add-module=/opt/modsecurity-${MODSECURITY_VERSION}/nginx/modsecurity/ \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock && \
    make && \
    make install
RUN mkdir /etc/nginx/{sites-available,sites-enabled,conf.d}
RUN wget -O /etc/init.d/nginx https://gist.githubusercontent.com/ston3o/17df45c1fd458c4698767d5b90e1cce0/raw/c998e9c6e0bd366dc8e88ef62c576cbe8d966ba8/nginx
RUN chmod +x /etc/init.d/nginx
RUN update-rc.d -f nginx defaults

CMD ["nginx", "-g", "daemon off;"]
