CREATE DATABASE IF NOT EXISTS popularity;

USE popularity;

CREATE TABLE IF NOT EXISTS popularity(
    id BIGINT AUTO_INCREMENT,
    fog_version VARCHAR(255) NULL,
    os_name VARCHAR(255) NULL,
    os_version VARCHAR(255) NULL,
    creation_time DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    INDEX creation_time (creation_time)
) ENGINE=InnoDB CHARACTER SET=utf8;


CREATE USER IF NOT EXISTS 'username-here'@'localhost' IDENTIFIED BY 'password-here';
GRANT ALL PRIVILEGES ON popularity.* TO 'username-here'@'localhost' IDENTIFIED BY 'password-here' WITH GRANT OPTION;
#GRANT ALL PRIVILEGES ON popularity.* TO 'username-here'@'%' IDENTIFIED BY 'password-here' WITH GRANT OPTION;
FLUSH PRIVILEGES;


