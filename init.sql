CREATE DATABASE IF NOT EXISTS fswiki_test;
USE fswiki_test;

CREATE TABLE IF NOT EXISTS config_tbl (
    key_name VARCHAR(255) PRIMARY KEY,
    value TEXT
);
