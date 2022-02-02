FROM magedin/php:8.0.15.2
MAINTAINER MagedIn Technology <support@magedin.com>


# ENVIRONMENT VARIABLES ------------------------------------------------------------------------------------------------

ENV APP_ROOT /var/www/html
ENV APP_HOME /var/www
ENV APP_USER www
ENV APP_GROUP www
ENV N98 /usr/local/bin/n98


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

## Install n98
RUN curl https://files.magerun.net/n98-magerun2.phar -o ${N98} \
  && chmod +x ${N98} \
  && chown ${APP_USER}:${APP_GROUP} ${N98}


# BASE CONFIGURATION ---------------------------------------------------------------------------------------------------

## Install Cron tabs.
#RUN printf '* *\t* * *\tapp\t%s/usr/local/bin/php /var/www/html/update/cron.php\n' >> /etc/crontab \
#  && printf '* *\t* * *\tapp\t%s/usr/local/bin/php /var/www/html/bin/magento cron:run\n' >> /etc/crontab \
#  && printf '* *\t* * *\tapp\t%s/usr/local/bin/php /var/www/html/bin/magento setup:cron:run\n#\n' >> /etc/crontab

#COPY bin/cronstart /usr/local/bin/

## Copy Configurations
COPY conf/php-fpm/zzz-magento.conf /usr/local/etc/php-fpm.d

RUN chown -R ${APP_USER}:${APP_GROUP} /usr/local/etc/*
