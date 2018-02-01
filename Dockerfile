FROM ubuntu:trusty

MAINTAINER Doitmagic <razvan@doitmagic.com>

ENV DEBIAN_FRONTEND noninteractive
ENV RABBITMQ_C_VER 0.8.0

# add NGINX official stable repository
RUN echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/nginx.list

# add PHP7 unofficial repository (https://launchpad.net/~ondrej/+archive/ubuntu/php)
RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/php.list

# install packages
RUN apt-get update && \
    apt-get -y --force-yes --no-install-recommends install \
    supervisor \
    curl \
    wget \
    cmake \
    nginx \
    git \
    pkg-config librabbitmq-dev  \
    php7.0-fpm php7.0-cli php7.0-common php7.0-curl php7.0-intl php7.0-json php7.0-mbstring php7.0-mcrypt php7.0-mysql php7.0-opcache \
    php7.0-bcmath  php7.0-soap php7.0-xml php-xml php7.0-xmlrpc php7.0-xsl php7.0-zip php7.0-gd php7.0-dev  php-pear php-dev


# Install the composer
RUN curl -sS http://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer
RUN chmod +x /usr/bin/composer

# configure NGINX as non-daemon
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# configure php-fpm as non-daemon
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.0/fpm/php-fpm.conf

# clear apt cache and remove unnecessary packages
RUN apt-get autoclean && apt-get -y autoremove

# add a phpinfo script for INFO purposes
RUN echo "<?php phpinfo();" >> /var/www/html/index.php

RUN set -xe \
    wget \
    cmake \
    openssl-dev

RUN apt-get -y install gcc make autoconf libc-dev pkg-config \
libssl-dev \
 librabbitmq-dev && \
pecl install amqp

RUN echo "extension=amqp.so" >> /etc/php/7.0/cli/php.ini \
echo "extension=amqp.so" >> /etc/php/7.0/fpm/php.ini

RUN phpenmod amqp


# copy config file for Supervisor
COPY config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# backup default default config for NGINX
RUN cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

# copy local defualt config file for NGINX
COPY config/nginx/default /etc/nginx/sites-available/default

# php7.0-fpm will not start if this directory does not exist
RUN mkdir /run/php

RUN update-alternatives --set php /usr/bin/php7.0

#RUN bash -c "echo extension=amqp.so > /etc/php7.0/conf.d/amqp.ini"
RUN service php7.0-fpm restart

# NGINX mountable directories for config and logs
VOLUME ["/var/www","/etc/nginx/sites-enabled","/etc/nginx/sites-available", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

WORKDIR /var/www
# NGINX ports
EXPOSE 80 443

CMD ["/usr/bin/supervisord"]
