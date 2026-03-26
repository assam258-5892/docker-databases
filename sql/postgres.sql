-- PostgreSQL: postgres database
-- docker compose exec -T postgres-service psql -U postgres -f /sql/postgres.sql

-- Debezium CDC user
DO $$ BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'debezium') THEN
        CREATE ROLE debezium WITH LOGIN PASSWORD 'dbz' SUPERUSER REPLICATION;
    END IF;
END $$;
GRANT ALL PRIVILEGES ON DATABASE postgres TO debezium;

DROP TABLE IF EXISTS products;

CREATE TABLE products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    category    VARCHAR(50),
    price       NUMERIC(10,2),
    stock       INT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO products (name, category, price, stock) VALUES
('Laptop Pro 15',             'Electronics',  1890000, 45),
('Wireless Keyboard',         'Peripherals',    59000, 200),
('27-inch Monitor',           'Electronics',   450000, 80),
('USB-C Hub',                 'Peripherals',    35000, 150),
('Bluetooth Mouse',           'Peripherals',    29000, 300),
('External SSD 1TB',          'Storage',       120000, 120),
('HD Webcam',                 'Peripherals',    55000, 90),
('Noise Cancelling Headset',  'Audio',         250000, 60),
('Graphics Tablet',           'Electronics',   380000, 35),
('Docking Station',           'Peripherals',   180000, 70);
