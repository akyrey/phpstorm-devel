FROM php:7.0-apache

RUN apt-get update -yqq \
    && apt-get -y install git zip autoconf pkg-config libssl-dev libpq-dev vim

# Custom php.ini
COPY ./php.ini /usr/local/etc/php

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');" \
    && mv composer.phar /usr/bin/composer

# Install CodeSniffer and MessDetector
RUN composer global require "squizlabs/php_codesniffer=*" \
    && composer global require "phpmd/phpmd"

# Install mongodb extension
RUN pecl install mongodb \
    && docker-php-ext-enable mongodb

# Enable mysql extension
RUN docker-php-ext-install pdo_mysql

RUN docker-php-ext-install pdo_pgsql \
    && docker-php-ext-enable pdo_pgsql

# Install xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Copy xdebug configration for remote debugging
COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Install bc-math extension
RUN docker-php-ext-install bcmath

# Add website
RUN mkdir -p /etc/apache2/from-host

RUN echo "" >> /etc/apache2/apache2.conf \
    && echo "# Include the configurations from the host machine" >> /etc/apache2/apache2.conf \
    && echo "IncludeOptional from-host/*.conf" >> /etc/apache2/apache2.conf

# Enable mod rewrite Apache
RUN a2enmod rewrite

EXPOSE 80

RUN usermod -u 1000 www-data
RUN groupmod -g 1000 www-data

CMD ["apache2-foreground"]
