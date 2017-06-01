#!/bin/bash

# Initialize MySQL database.
# ADD this file into the container via Dockerfile.
# Assuming you specify a VOLUME ["/var/lib/mysql"] or `-v /var/lib/mysql` on the `docker run` command…
# Once built, do e.g. `docker run your_image /path/to/docker-mysql-initialize.sh`
# Again, make sure MySQL is persisting data outside the container for this to have any effect.

set -e
set -x

mysqld --initialize

# Start the MySQL daemon in the background.
/usr/sbin/mysqld &
mysql_pid=$!

cat /var/log/mysql/error.log

pgrep -lf mysql

#until mysqladmin ping >/dev/null 2>&1; do
until mysqladmin ping; do
  echo -n "."; sleep 1
done

# Permit root login without password from outside container.
mysql -e "GRANT ALL ON *.* TO root@'%' IDENTIFIED BY '' WITH GRANT OPTION"

# create the default database from the ADDed file.
mysql < /var/tmp/setup.sql

# Tell the MySQL daemon to shutdown.
mysqladmin shutdown

# Wait for the MySQL daemon to exit.
wait $mysql_pid

