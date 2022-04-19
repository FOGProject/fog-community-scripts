CREATE DATABASE IF NOT EXISTS external_reporting;

USE external_reporting;

CREATE TABLE IF NOT EXISTS versions_out_there(
    id BIGINT AUTO_INCREMENT,
    fog_version VARCHAR(255) NULL,
    os_name VARCHAR(255) NULL,
    os_version VARCHAR(255) NULL,
    creation_time DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    INDEX creation_time (creation_time)
) ENGINE=InnoDB CHARACTER SET=utf8;


CREATE TABLE IF NOT EXISTS kernels_out_there(
    id BIGINT AUTO_INCREMENT,
    kernel_version VARCHAR(255) NULL,
    creation_time DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    PRIMARY KEY (id),
    INDEX kernels_index (creation_time)
) ENGINE=InnoDB CHARACTER SET=utf8;


CREATE USER IF NOT EXISTS 'username-here'@'localhost' IDENTIFIED BY 'password-here';
GRANT ALL PRIVILEGES ON external_reporting.* TO 'username-here'@'localhost' IDENTIFIED BY 'password-here' WITH GRANT OPTION;
#GRANT ALL PRIVILEGES ON external_reporting.* TO 'username-here'@'%' IDENTIFIED BY 'password-here' WITH GRANT OPTION;
FLUSH PRIVILEGES;


