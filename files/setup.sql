DELETE FROM mysql.user;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'test' with GRANT OPTION;

FLUSH PRIVILEGES;
DROP DATABASE IF EXISTS test;