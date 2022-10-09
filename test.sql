CREATE DATABASE test;

USE test;

CREATE TABLE user
(
    id      int       NOT NULL AUTO_INCREMENT,
    name    char(50)  NOT NULL ,
    address char(50)  NOT NULL ,
    PRIMARY KEY (id)
) ENGINE=InnoDB;