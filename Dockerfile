ARG PHP_VERSION=8.3
ARG FRANKEN_PHP_VERSION=builder
ARG OS=bookworm
ARG USER=www-data

FROM dunglas/frankenphp:${FRANKEN_PHP_VERSION}-php${PHP_VERSION}-${OS}

LABEL org.opencontainers.image.title="frankenphp" \
      org.opencontainers.image.description="FrankenPHP (PHP 8.3, Debian bookworm) with common extensions, Composer 2.2 and sendmail" \
      org.opencontainers.image.authors="Yohan Naftali" \
      org.opencontainers.image.source="https://github.com/yohannaftali/dockerhub-yohannaftali-frankenphp"

WORKDIR /app

RUN \
  # Use "adduser -D ${USER}" for alpine based distros
  useradd -D ${USER}; \
  # Remove default capability
  setcap -r /usr/local/bin/frankenphp;

USER ${USER}

ENV TZ=Asia/Jakarta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
  build-essential \
  curl \
  gifsicle \
  jpegoptim \
  libcurl4 \
  libcurl4-openssl-dev \
  libfreetype6-dev \
  libicu-dev \
  libjpeg62-turbo-dev \
  libmagickwand-dev \
  libmcrypt-dev \
  libnss3-tools \
  libonig-dev \
  libpng-dev \
  libpq-dev \
  libwebp-dev \
  libxml2-dev \
  libzip-dev \
  nano \
  optipng \
  pngquant \
  sendmail \
  unzip \
  wget \
  zip \
  zlib1g-dev

RUN install-php-extensions \
  bcmath \
  exif \
  gd \
  intl \
  mbstring \
  mysqli \
  opcache \
  pcntl \
  pdo \
  pdo_mysql \
  soap \
  zip

RUN echo "sendmail_path=/usr/sbin/sendmail -t -i" >> /usr/local/etc/php/conf.d/sendmail.ini
RUN sed -i '/#!\/bin\/sh/aservice sendmail restart' /usr/local/bin/docker-php-entrypoint
RUN sed -i '/#!\/bin\/sh/aecho "$(hostname -i)\t$(hostname) $(hostname).localhost" >> /etc/hosts' /usr/local/bin/docker-php-entrypoint

COPY --from=composer:lts /usr/bin/composer /usr/local/bin/composer
