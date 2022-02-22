FROM tiagosampaio/php:7.4.27

ARG GOSU_VERSION=1.11

# ENVIRONMENT VARIABLES ------------------------------------------------------------------------------------------------

ENV APP_ROOT /var/www/html
ENV APP_HOME /var/www
ENV APP_USER www
ENV APP_GROUP www

ENV DEBUG false
ENV UPDATE_UID_GID false
ENV SET_DOCKER_HOST false

ENV N98 /usr/local/bin/n98

# ADD USER AND GROUP ---------------------------------------------------------------------------------------------------

## Add user www with ID 1000. It means that the user in your local machine will be the same user in Docker container.
RUN groupadd -g 1000 ${APP_GROUP} && useradd -g 1000 -u 1000 -d ${APP_HOME} -s /bin/bash ${APP_USER}


# BASE INSTALLATION ----------------------------------------------------------------------------------------------------

## Install Tools
RUN apt-get update && apt-get install -y \
  cron

## Install NodeJs
RUN apt-get install -y gnupg \
  && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
  && apt-get install -y nodejs \
  && mkdir ${APP_HOME}/.config ${APP_HOME}/.npm \
  && chown ${APP_USER}:${APP_GROUP} ${APP_HOME}/.config ${APP_HOME}/.npm \
  && npm install -g grunt-cli

## Install Blackfire
RUN curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
  && mkdir -p /tmp/blackfire \
  && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
  && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
  && ( echo extension=blackfire.so \
  && echo blackfire.agent_socket=tcp://blackfire:8707 ) > $(php -i | grep "additional .ini" | awk '{print $9}')/blackfire.ini \
  && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

## Install Ioncube
RUN cd /tmp \
  && curl -O https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
  && tar zxvf ioncube_loaders_lin_x86-64.tar.gz \
  && export PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;") \
  && export PHP_EXT_DIR=$(php-config --extension-dir) \
  && cp "./ioncube/ioncube_loader_lin_${PHP_VERSION}.so" "${PHP_EXT_DIR}/ioncube.so" \
  && rm -rf ./ioncube \
  && rm ioncube_loaders_lin_x86-64.tar.gz

## Install Sendmail for MailHog
RUN curl -sSLO https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64 \
  && chmod +x mhsendmail_linux_amd64 \
  && mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

## Install n98
RUN curl https://files.magerun.net/n98-magerun2.phar -o ${N98} \
  && chmod +x ${N98} \
  && chown ${APP_USER}:${APP_GROUP} ${N98}


# BASE CONFIGURATION ---------------------------------------------------------------------------------------------------

COPY conf/conf.d/*.ini /usr/local/etc/php/conf.d/
COPY conf/php.ini /usr/local/etc/php/php.ini
COPY conf/php-fpm.conf /usr/local/etc/

COPY fpm-healthcheck.sh /usr/local/bin/fpm-healthcheck.sh
RUN ["chmod", "+x", "/usr/local/bin/fpm-healthcheck.sh"]

HEALTHCHECK --retries=3 CMD ["bash", "/usr/local/bin/fpm-healthcheck.sh"]

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN ["chmod", "+x", "/docker-entrypoint.sh"]

RUN touch ${APP_HOME}/.bashrc \
  && echo "alias ll=\"ls $LS_OPTIONS -lah\"" >> ${APP_HOME}/.bashrc \
  && echo "alias l=\"ll\"" >> ${APP_HOME}/.bashrc

RUN mkdir -p ${APP_HOME}/scripts
COPY ./scripts/* ${APP_HOME}/scripts

RUN mkdir -p ${APP_ROOT} \
  && chown -R ${APP_USER}:${APP_GROUP} ${APP_HOME} /usr/local/etc/php/conf.d

COPY conf/php-fpm/zzz-magento.conf /usr/local/etc/php-fpm.d

RUN chown -R ${APP_USER}:${APP_GROUP} /usr/local/etc/*

VOLUME ${APP_HOME}

ENTRYPOINT ["/docker-entrypoint.sh"]

USER root

WORKDIR ${APP_ROOT}

CMD ["php-fpm", "-R"]

#-----------------------------------------------------------------------------------------------------------------------
