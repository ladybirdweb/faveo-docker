FROM nginx:1.11.10

MAINTAINER Himanshu Verma <himanshu@attabot.io>

# Install necessary packages 

RUN apt-get update -y && apt-get install -y curl git \
  php5-fpm php5-mcrypt  \
	php5-intl php-apc php5-gd php5-intl php5-mysql php5-pgsql php5-curl \
	php5-xmlrpc php5-imap php-pear php5-cli cron && rm -rf /var/lib/apt/lists/*

RUN php5enmod mcrypt

RUN curl -sS https://getcomposer.org/installer | php && \
		mv composer.phar /usr/local/bin/composer

RUN sed -i 's/user  nginx/user  www-data/g' /etc/nginx/nginx.conf

# Force PHP to log to nginx
RUN echo "catch_workers_output = yes" >> /etc/php5/fpm/php-fpm.conf

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
        && ln -sf /dev/stderr /var/log/nginx/error.log

# Enable php by default
ADD default.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/

RUN rm -rf *

# Clone the project from git
RUN git clone https://github.com/ladybirdweb/faveo-helpdesk.git .

RUN composer install
RUN chgrp -R www-data . storage bootstrap/cache
RUN chmod -R ug+rwx . storage bootstrap/cache

# Add to crontab file

RUN touch /etc/cron.d/faveo-cron

RUN echo '* * * * * php /usr/share/nginx/artisan schedule:run > /dev/null 2>&1' >>/etc/cron.d/faveo-cron

RUN chmod 0644 /etc/cron.d/faveo-cron

RUN crontab /etc/cron.d/faveo-cron

RUN sed -i "s/max_execution_time = .*/max_execution_time = 120/" /etc/php5/fpm/php.ini

CMD cron && service php5-fpm start && nginx -g "daemon off;"
