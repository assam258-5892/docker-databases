-- MariaDB: testdb database
-- docker compose exec -T mariadb-service mariadb < /sql/mariadb.sql

-- Debezium CDC user
CREATE USER IF NOT EXISTS 'debezium'@'%' IDENTIFIED BY 'dbz';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'debezium'@'%';
GRANT ALL PRIVILEGES ON testdb.* TO 'debezium'@'%';
FLUSH PRIVILEGES;

CREATE DATABASE IF NOT EXISTS testdb;
USE testdb;

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    product_name  VARCHAR(100),
    quantity      INT,
    total_price   DECIMAL(10,2),
    order_date    DATE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO orders (customer_name, product_name, quantity, total_price, order_date) VALUES
('Kim Minsu',    'Laptop Pro 15',              1, 1890000, '2024-01-15'),
('Lee Jiyoung',  'Wireless Keyboard',          3,  177000, '2024-02-03'),
('Park Junho',   '27-inch Monitor',            2,  900000, '2024-02-20'),
('Jung Sujin',   'USB-C Hub',                  5,  175000, '2024-03-08'),
('Choi Younghun','Bluetooth Mouse',            2,   58000, '2024-03-15'),
('Han Mirae',    'External SSD 1TB',           1,  120000, '2024-04-01'),
('Oh Sejin',     'HD Webcam',                  1,   55000, '2024-04-22'),
('Yoon Hana',    'Noise Cancelling Headset',   1,  250000, '2024-05-10'),
('Seo Donghyun', 'Graphics Tablet',            1,  380000, '2024-06-05'),
('Lim Chaewon',  'Docking Station',            2,  360000, '2024-06-18');
