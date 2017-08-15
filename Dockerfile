FROM debian:stretch

# Dependencies
RUN echo "deb-src http://deb.debian.org/debian stretch main" >> /etc/apt/sources.list
RUN apt-get update --fix-missing
RUN apt-get install -y git wget build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev libcurl4-openssl-dev automake pkgconf dialog init-system-helpers

# Modsecurity
RUN git clone https://github.com/SpiderLabs/ModSecurity-nginx /opt/modsecurity-nginx
RUN git clone -b v3/master --recursive https://github.com/SpiderLabs/ModSecurity.git /opt/modsecurity && \
    cd /opt/modsecurity/ && \
    ./build.sh && \
    ./configure && \
    make && \
    make install

# Nginx
RUN apt-get -qy build-dep nginx
RUN cd /opt && apt-get source nginx && mv nginx-* nginx
RUN cd /opt/nginx && sed -i -e 's%\./configure%./configure --add-module=/opt/modsecurity-nginx%' debian/rules
RUN cd /opt/nginx && echo '\noverride_dh_shlibdeps:\n\tdh_shlibdeps --dpkg-shlibdeps-params=--ignore-missing-info' >> debian/rules
RUN cd /opt/nginx && dpkg-buildpackage -b
RUN dpkg -i /opt/nginx-common_*.deb
RUN dpkg -i /opt/libnginx-mod-*.deb
RUN dpkg -i /opt/nginx-full_*.deb
RUN dpkg -i /opt/nginx_*.deb

# Enable modsecurity.conf
RUN cp /opt/modsecurity/modsecurity.conf-recommended /etc/nginx/modsecurity.conf
RUN sed -i -e 's/^\s*SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsecurity.conf
RUN sed -i -e 's%http {%http {\n\tmodsecurity on;\n\tmodsecurity_rules_file /etc/nginx/modsecurity.conf;%g' /etc/nginx/nginx.conf

# Install OWASP ModSecurity Core Rule Set
RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /opt/owasp
RUN cp -r /opt/owasp/rules/ /etc/nginx/
RUN cp /opt/owasp/crs-setup.conf.example /etc/nginx/crs-setup.conf
RUN echo 'Include crs-setup.conf' >> /etc/nginx/modsecurity.conf
RUN echo 'Include rules/*.conf' >> /etc/nginx/modsecurity.conf
RUN rm /etc/nginx/rules/REQUEST-910-IP-REPUTATION.conf

# Cleanup
RUN rm /opt/*.deb /opt/*.tar.gz /opt/*.tar.xz /opt/*.dsc /opt/*.buildinfo /opt/*.changes

CMD ["nginx", "-g", "daemon off;"]
