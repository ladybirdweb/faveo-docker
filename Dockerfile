FROM ubuntu:16.04

MAINTAINER Ladybird Web Solutions <support@ladybirdweb.com>

ENV DEBIAN_FRONTEND noninteractive

# mainline or stable
ENV NGINX_REPO      stable
ENV NGINX_VERSION   1.8.1-1+trusty0

# get add-apt-respository for repo bits
RUN apt-get -qq update && \
    apt-get -yf install software-properties-common

# install nginx mysql and composer and nodejs and npm
RUN add-apt-repository --yes ppa:nginx/${NGINX_REPO} && \
    LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php && \
    apt-get -qq update && \
    apt-get -yf --force-yes install nginx git sl curl mlocate dos2unix bash-completion openssl wget\
    php7.1-xml php7.1-xsl php7.1-mbstring php7.1-readline php7.1-zip php7.1-mysql php7.1-phpdbg php7.1-interbase \
    php7.1-sybase php7.1 php7.1-sqlite3 php7.1-tidy php7.1-opcache php7.1-pspell php7.1-json php7.1-xmlrpc php7.1-curl \
    php7.1-ldap php7.1-bz2 php7.1-cgi php7.1-imap php7.1-cli php7.1-dba php7.1-dev php7.1-intl php7.1-fpm php7.1-recode php7.1-odbc \
    php7.1-gmp php7.1-common php7.1-pgsql php7.1-bcmath php7.1-snmp php7.1-soap php7.1-gd php7.1-enchant nodejs npm git && \
    curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# create back up of nginx configuration file
RUN  mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.back

# download nginx configuration file from Faveo Helpdesk Site and update nginx config file
RUN wget -O /etc/nginx/nginx.conf https://support.faveohelpdesk.com/uploads/ubuntu16.04/faveo-nginx-conf.txt
ADD default.conf /etc/nginx/conf.d/faveo-helpdesk.conf

# remove default nginx configuration file
RUN rm -rf /etc/nginx/conf.d/default.conf

# add Faveo PHP FPM configuration file
ADD faveo.conf /etc/php/7.1/fpm/pool.d/faveo_php.conf

# change workgin directory to nginx
WORKDIR /usr/share/nginx/

RUN rm -rf *

# Clone the project from git
RUN git clone https://github.com/ladybirdweb/faveo-helpdesk.git .

# Install project depencencies 
RUN composer install

# Chnage project permissions
RUN chgrp -R www-data . storage bootstrap/cache
RUN chmod -R ug+rwx . storage bootstrap/cache

# Add to crontab file

RUN touch /etc/cron.d/faveo-cron

RUN echo '* * * * * php /usr/share/nginx/artisan schedule:run > /dev/null 2>&1' >>/etc/cron.d/faveo-cron

RUN chmod 0644 /etc/cron.d/faveo-cron

RUN crontab /etc/cron.d/faveo-cron

RUN sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/7.1/fpm/php.ini


CMD cron && service php7.1-fpm start && nginx -g "daemon off;"
