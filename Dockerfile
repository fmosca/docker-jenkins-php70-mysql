# This Dockerfile is used to build an image containing basic stuff to be used as a Jenkins slave build node.
FROM ubuntu:xenial
MAINTAINER Francesco Mosca <francesco.mosca@doing.com>

RUN sed -i 's/archive/us.archive/g' /etc/apt/sources.list

# disable interactive functions
ENV DEBIAN_FRONTEND noninteractive

# set default java environment variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64


# In case you need proxy
#RUN echo 'Acquire::http::Proxy "http://127.0.0.1:8080";' >> /etc/apt/apt.conf

# Add locales after locale-gen as needed
# Upgrade packages on image
# Preparations for sshd
RUN apt-get -q update &&\
    apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends openssh-server software-properties-common &&\
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd &&\
    mkdir -p /var/run/sshd

RUN add-apt-repository ppa:openjdk-r/ppa -y &&\
    apt-get -q update

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Set mysql root password
RUN echo "mysql-server-5.7 mysql-server/root_password password test" | debconf-set-selections
RUN echo "mysql-server-5.7 mysql-server/root_password_again password test" | debconf-set-selections


# Install JDK 8 (latest edition)
RUN apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends \
    openjdk-8-jre-headless locales sudo

RUN locale-gen en_US.UTF-8

RUN apt-get -q install -y -o Dpkg::Options::="--force-confnew"  --no-install-recommends \
    curl git mysql-client mysql-server \
    php-mysql php-gd php-pear php-zip php-curl curl lynx-cur php-mcrypt php-intl php-imap freetds-common php-sybase php-mbstring php-bcmath php-bz2 php-json php-readline php-sqlite3 php-xml php-xmlrpc php-tidy php-xsl php-soap &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

RUN apt-get -q autoremove &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin


RUN phpenmod mcrypt

# Set user jenkins to the image
RUN useradd -m -d /home/jenkins -s /bin/sh jenkins &&\
    echo "jenkins:jenkins" | chpasswd

# Add public key for Jenkins login
RUN mkdir /home/jenkins/.ssh
COPY /files/authorized_keys /home/jenkins/.ssh/authorized_keys
RUN chown -R jenkins /home/jenkins
RUN chgrp -R jenkins /home/jenkins
RUN chmod 600 /home/jenkins/.ssh/authorized_keys
RUN chmod 700 /home/jenkins/.ssh

# Add the jenkins user to sudoers
RUN echo "jenkins  ALL=(ALL)  ALL" >> etc/sudoers

# Set Name Servers
COPY /files/resolv.conf /etc/resolv.conf

# Install Composer

RUN curl -sS https://getcomposer.org/installer | \
    php -- --install-dir=/usr/bin/ --filename=composer

# Install prestissimo 

RUN sudo -H -u jenkins bash -c ' \
        export COMPOSER_BIN_DIR=/home/jenkins/bin; \
        export COMPOSER_HOME=/home/jenkins/.composer; \
	composer global require "hirak/prestissimo=*" --prefer-source --no-interaction; \
	'

# Prepare shared volume

RUN mkdir /mnt/shared

# Prepare php

ENV PHP_MEMORY_LIMIT 1024M
ENV PHP_DATE_TIMEZONE Europe/Rome 

RUN echo "memory_limit=${PHP_MEMORY_LIMIT}" > /etc/php/7.0/cli/conf.d/10-memory_limit.ini
RUN echo "date.timezone=${PHP_DATE_TIMEZONE}" > /etc/php/7.0/cli/conf.d/10-date_timezone.ini

# Prepare mysql

COPY /files/custom.cnf /etc/mysql/conf.d/custom.cnf
COPY /files/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
RUN chmod +x /entrypoint.sh



EXPOSE 3306
EXPOSE 22

USER jenkins
RUN ssh-keyscan -t rsa bitbucket.org >> /home/jenkins/.ssh/known_hosts
USER root

CMD ["/usr/sbin/sshd", "-D"]
