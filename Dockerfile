FROM debian:stretch

# Dependencies
RUN echo "deb-src http://deb.debian.org/debian stretch main" >> /etc/apt/sources.list
RUN apt-get update --fix-missing
RUN apt-get install -y git wget build-essential libpcre3 libpcre3-dev libssl-dev libtool autoconf apache2-dev libxml2-dev libcurl4-openssl-dev automake pkgconf dialog

# Modsecurity
RUN git clone -b nginx_refactoring https://github.com/SpiderLabs/ModSecurity.git /opt/modsecurity && \
    cd /opt/modsecurity/ && \
    ./autogen.sh && \
    ./configure --enable-standalone-module && \
    make

# Nginx
RUN apt-get -qy build-dep nginx
RUN cd /opt && apt-get source nginx
RUN cd /opt/nginx-* && sed -i -e 's%\./configure%./configure --add-module=/opt/modsecurity/nginx/modsecurity%' debian/rules
RUN cd /opt/nginx-* && dpkg-buildpackage -b
RUN apt-get install -y init-system-helpers
RUN dpkg -i /opt/nginx-common_*.deb
RUN dpkg -i /opt/libnginx-mod-*.deb
RUN dpkg -i /opt/nginx-full_*.deb

# Enable modsecurity.conf
RUN cp /opt/modsecurity/modsecurity.conf-recommended /etc/nginx/modsecurity.conf
RUN cp /opt/modsecurity/unicode.mapping /etc/nginx/unicode.mapping
RUN sed -i -e 's/^\s*SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsecurity.conf
RUN sed -i -e 's/http {/http {\n        ModSecurityEnabled on;\n        ModSecurityConfig modsecurity.conf;/g' /etc/nginx/nginx.conf

# Install OWASP ModSecurity Core Rule Set
RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /opt/owasp
RUN cp -r /opt/owasp/rules/ /etc/nginx/
RUN cp /opt/owasp/crs-setup.conf.example /etc/nginx/crs-setup.conf
RUN echo 'Include crs-setup.conf' >> /etc/nginx/modsecurity.conf
RUN echo 'Include rules/*.conf' >> /etc/nginx/modsecurity.conf

# Fix bug Audit log: Failed to unlock global mutex: Permission denied
RUN sed -i -e 's/#SecAuditLogStorageDir/SecAuditLogStorageDir/g' /etc/nginx/modsecurity.conf
RUN sed -i -e 's/SecAuditLogType Serial/SecAuditLogType Concurrent/g' /etc/nginx/modsecurity.conf
RUN bash -c 'mkdir -p /opt/modsecurity/var/{audit,log}'
RUN chmod -R 777 /opt/modsecurity/var/

# Cleanup
RUN rm /opt/*.deb /opt/*.tar.gz /opt/*.tar.xz /opt/*.dsc /opt/*.buildinfo /opt/*.changes

CMD ["nginx", "-g", "daemon off;"]
