FROM ubuntu:trusty
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
			org.label-schema.name="docker-pdns" \
			org.label-schema.description="PowerDNS Authoritative server and Poweradmin" \
			org.label-schema.url="http://andradaprieto.es" \
			org.label-schema.vcs-ref=$VCS_REF \
			org.label-schema.vcs-url="https://github.com/jandradap/LARP" \
			org.label-schema.vendor="Jorge Andrada Prieto" \
			org.label-schema.version=$VERSION \
			org.label-schema.schema-version="1.0" \
			maintainer="Jorge Andrada Prieto <jandradap@gmail.com>" \
			org.label-schema.docker.cmd="docker run --name pdns-master --link mysql:db -d -p 53:53/udp -p 53:53 -p 8080:80 jorgeandrada/docker-pdns"

COPY assets/apt/preferences.d/pdns /etc/apt/preferences.d/pdns
RUN apt-get update && apt-get install -y curl \
	&& curl https://repo.powerdns.com/FD380FBB-pub.asc | sudo apt-key add - \
	&& echo "deb [arch=amd64] http://repo.powerdns.com/ubuntu trusty-auth-40 main" > /etc/apt/sources.list.d/pdns.list


RUN apt-get update && apt-get install -y \
	wget \
	git \
	supervisor \
	mysql-client \
	nginx \
	php5-fpm \
	php5-mcrypt \
	php5-mysqlnd \
	pdns-server \
	pdns-backend-mysql \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

### PDNS ###

#RUN cd /tmp && wget https://downloads.powerdns.com/releases/deb/pdns-static_${VERSION}_amd64.deb && dpkg -i pdns-static_${VERSION}_amd64.deb && rm pdns-static_${VERSION}_amd64.deb
#RUN useradd --system pdns

COPY assets/nginx/nginx.conf /etc/nginx/nginx.conf
COPY assets/nginx/vhost.conf /etc/nginx/sites-enabled/vhost.conf
COPY assets/nginx/fastcgi_params /etc/nginx/fastcgi_params

COPY assets/php/php.ini /etc/php5/fpm/php.ini
COPY assets/php/php-cli.ini /etc/php5/cli/php.ini

COPY assets/pdns/pdns.conf /etc/powerdns/pdns.conf
COPY assets/pdns/pdns.d/ /etc/powerdns/pdns.d/
COPY assets/mysql/pdns.sql /pdns.sql

### PHP/Nginx ###
RUN rm /etc/nginx/sites-enabled/default && \
	php5enmod mcrypt && \
	mkdir -p /var/www/html/ \
	&& cd /var/www/html \
	&& git clone https://github.com/wociscz/poweradmin.git . \
	&& git checkout 98ecbb5692d4f9bc42110ec478be63eb5651c6de \
	&& rm -R /var/www/html/install

COPY assets/poweradmin/config.inc.php /var/www/html/inc/config.inc.php
COPY assets/mysql/poweradmin.sql /poweradmin.sql
RUN chown -R www-data:www-data /var/www/html/ \
	&& chmod 644 /etc/powerdns/pdns.d/pdns.*

### SUPERVISOR ###
COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh

EXPOSE 53 80
EXPOSE 53/udp

CMD ["/bin/bash", "/start.sh"]
