#Usar a imagem oficial do Composer para obter o binário
FROM composer:latest AS composer_stage

# Use a imagem oficial do PHP 5.6 com Apache
FROM php:8.1-apache

# Instalar Composer
COPY --from=composer_stage /usr/bin/composer /usr/local/bin/composer

# Atualizar certificados CA
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && update-ca-certificates

RUN echo "deb http://archive.debian.org/debian stretch main" > /etc/apt/sources.list

WORKDIR /var/www/html

# Copiar arquivos de configuração para o contêiner
COPY ./apache2/sites-available /etc/apache2/sites-available/
COPY ./apache2/hosts /etc/hosts 

# Instalação de dependências e módulos do PHP
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libmcrypt-dev \
    libicu-dev \
    libxml2-dev \
    libzip-dev \
    libxslt-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    curl \
    git \
    zip \
    unzip \
    libonig-dev \
    libmagickwand-dev --no-install-recommends 

# Instalar extensões do PHP necessárias
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install curl gd mbstring mysqli pdo pdo_mysql intl xml zip exif soap xsl

RUN docker-php-ext-enable zip

# Instalar e habilitar o Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Copiar arquivo de configuração php.ini customizado
COPY ./php/php.ini /usr/local/etc/php/php.ini
COPY ./php/conf.d/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
COPY ./apache2/conf-available/servername.conf /etc/apache2/conf-available/servername.conf

# Ativar módulos do Apache (rewrite, headers, SSL)
RUN a2enconf servername
RUN a2enmod rewrite headers ssl

# Reiniciar o Apache no final
CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]

# Expor portas necessárias
EXPOSE 881
EXPOSE 44381