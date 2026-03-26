-- MySQL: testdb database
-- docker compose exec -T mysql-service mysql < /sql/mysql.sql

-- Debezium CDC user
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'dbz';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
GRANT ALL PRIVILEGES ON testdb.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    email       VARCHAR(100),
    phone       VARCHAR(20),
    grade       VARCHAR(20),
    join_date   DATE,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO customers (name, email, phone, grade, join_date) VALUES
('Kim Minsu',     'minsu@example.com',    '010-1234-5678', 'VIP',    '2020-01-10'),
('Lee Jiyoung',   'jiyoung@example.com',  '010-2345-6789', 'GOLD',   '2020-03-22'),
('Park Junho',    'junho@example.com',    '010-3456-7890', 'SILVER', '2021-05-15'),
('Jung Sujin',    'sujin@example.com',    '010-4567-8901', 'VIP',    '2019-11-03'),
('Choi Younghun', 'younghun@example.com', '010-5678-9012', 'GOLD',   '2021-07-20'),
('Han Mirae',     'mirae@example.com',    '010-6789-0123', 'SILVER', '2022-02-14'),
('Oh Sejin',      'sejin@example.com',    '010-7890-1234', 'GOLD',   '2020-09-08'),
('Yoon Hana',     'hana@example.com',     '010-8901-2345', 'SILVER', '2022-06-30'),
('Seo Donghyun',  'donghyun@example.com', '010-9012-3456', 'VIP',    '2019-04-17'),
('Lim Chaewon',   'chaewon@example.com',  '010-0123-4567', 'GOLD',   '2021-12-25');
