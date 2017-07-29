FROM debian:jessie

# Dependencies
RUN apt-get update --fix-missing
RUN apt-get install -y git wget curl build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev libcurl4-openssl-dev automake pkgconf lsb-release quilt

# Modsecurity
RUN git clone -b nginx_refactoring https://github.com/SpiderLabs/ModSecurity.git /opt/modsecurity && \
    cd /opt/modsecurity/ && \
    ./autogen.sh && \
    ./configure --enable-standalone-module && \
    make

# Nginx
RUN echo "deb-src http://deb.debian.org/debian jessie main" >> /etc/apt/sources.list && apt-get update
RUN apt-get -qy build-dep nginx
RUN cd /opt && apt-get source nginx
RUN cd /opt/nginx-* && sed -i -e 's%\./configure%./configure --add-module=/opt/modsecurity/nginx/modsecurity%' debian/rules
RUN cd /opt/nginx-* && dpkg-buildpackage -b
RUN apt-get install -y init-system-helpers
RUN dpkg -i /opt/nginx-common_*.deb
RUN dpkg -i /opt/nginx-full_*.deb

CMD ["nginx", "-g", "daemon off;"]
