# Debezium CDC Setup

## Key Configurations

### docker-compose.yml

CDC requires specific database startup options. These are already configured in `docker-compose.yml`:

| Service | Parameter | Purpose |
|---------|-----------|---------|
| PostgreSQL | `wal_level=logical` | Enable logical replication for CDC |
| MariaDB | `--log-bin` | Enable binary logging |
| MariaDB | `--binlog-format=ROW` | Row-based replication (required by Debezium) |
| MariaDB | `--server-id=1` | Unique server ID for replication |
| MySQL | `--server-id=2` | Unique server ID for replication (binlog on by default in 8.4) |

### Debezium Image

The Debezium container uses a custom Dockerfile (`Dockerfile/debezium/`) that replaces the bundled Oracle JDBC driver with a 23ai-compatible version (`ojdbc11.jar`). Use `--build` when starting services.

### CDC User (`debezium/dbz`)

Each SQL script creates a `debezium` user with the following permissions:

| DB | Key Permissions |
|----|----------------|
| MySQL | `REPLICATION SLAVE`, `REPLICATION CLIENT`, `ALL ON testdb.*` |
| MariaDB | `REPLICATION SLAVE`, `REPLICATION CLIENT`, `ALL ON testdb.*` |
| PostgreSQL | `SUPERUSER`, `REPLICATION`, `ALL ON DATABASE postgres` |

### Sink Connector

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `schema.evolution` | `basic` | Allow auto-creation of target tables |
| `insert.mode` | `upsert` | Insert or update on conflict |
| `delete.enabled` | `true` | Propagate DELETE operations |
| `primary.key.mode` | `record_key` | Use source record key as primary key |

## Prerequisites

Start all services:

```bash
docker compose up -d --build
```

Wait until all database containers are healthy before proceeding.

## Step 1: Initialize Databases

Run the SQL scripts to create Debezium CDC users and sample tables:

```bash
docker compose exec -T mysql-service mysql < sql/mysql.sql
docker compose exec -T mariadb-service mariadb < sql/mariadb.sql
docker compose exec -T postgres-service psql -U postgres -f sql/postgres.sql
docker compose exec -T oracle-service sqlplus system/manager@FREE @/sql/oracle.sql
```

This creates a `debezium/dbz` user in each database with the required CDC permissions.

## Step 2: Verify Debezium is Running

```bash
curl http://localhost:8083/connector-plugins
```

## Step 3: Register Source Connectors

### MariaDB → Kafka

```bash
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "src-mariadb",
  "config": {
    "connector.class": "io.debezium.connector.mariadb.MariaDbConnector",
    "database.hostname": "mariadb",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.server.id": "12360",
    "database.ssl.mode": "disabled",
    "topic.prefix": "mdb",
    "table.include.list": "testdb.orders",
    "schema.history.internal.kafka.bootstrap.servers": "kafka:29092",
    "schema.history.internal.kafka.topic": "schema-changes.mdb"
  }
}'
```

### PostgreSQL → Kafka

```bash
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "postgres-source",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.dbname": "postgres",
    "topic.prefix": "postgres",
    "table.include.list": "public.products",
    "plugin.name": "pgoutput",
    "publication.name": "dbz_products"
  }
}'
```

### MySQL → Kafka

```bash
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "mysql-source",
  "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "database.hostname": "mysql",
    "database.port": "3306",
    "database.user": "debezium",
    "database.password": "dbz",
    "database.server.id": "12351",
    "topic.prefix": "mysql",
    "table.include.list": "testdb.customers",
    "schema.history.internal.kafka.bootstrap.servers": "kafka:29092",
    "schema.history.internal.kafka.topic": "schema-changes.mysql-src"
  }
}'
```

### Oracle (not supported)

Oracle 23ai (26ai Free) is not supported by Debezium 3.0.0 / 2.7.3 due to version parsing failure (`Failed to resolve Oracle database version`).

## Step 4: Register Sink Connectors

### MariaDB orders → PostgreSQL

```bash
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "sink-mariadb-to-postgres",
  "config": {
    "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",
    "connection.url": "jdbc:postgresql://postgres:5432/postgres",
    "connection.username": "debezium",
    "connection.password": "dbz",
    "topics": "mdb.testdb.orders",
    "auto.create": "true",
    "auto.evolve": "true",
    "schema.evolution": "basic",
    "insert.mode": "upsert",
    "primary.key.mode": "record_key",
    "primary.key.fields": "id",
    "delete.enabled": "true",
    "table.name.format": "orders"
  }
}'
```

### PostgreSQL products → MySQL

```bash
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "sink-postgres-to-mysql",
  "config": {
    "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",
    "connection.url": "jdbc:mysql://mysql:3306/testdb",
    "connection.username": "debezium",
    "connection.password": "dbz",
    "topics": "postgres.public.products",
    "auto.create": "true",
    "auto.evolve": "true",
    "schema.evolution": "basic",
    "insert.mode": "upsert",
    "primary.key.mode": "record_key",
    "primary.key.fields": "id",
    "delete.enabled": "true",
    "table.name.format": "products"
  }
}'
```

### MySQL customers → MariaDB

```bash
curl -X POST http://localhost:8083/connectors -H "Content-Type: application/json" -d '{
  "name": "sink-mysql-to-mariadb",
  "config": {
    "connector.class": "io.debezium.connector.jdbc.JdbcSinkConnector",
    "connection.url": "jdbc:mariadb://mariadb:3306/testdb",
    "connection.username": "debezium",
    "connection.password": "dbz",
    "topics": "mysql.testdb.customers",
    "auto.create": "true",
    "auto.evolve": "true",
    "schema.evolution": "basic",
    "insert.mode": "upsert",
    "primary.key.mode": "record_key",
    "primary.key.fields": "id",
    "delete.enabled": "true",
    "table.name.format": "customers"
  }
}'
```

## Step 5: Verify

Check all connector statuses:

```bash
curl -s http://localhost:8083/connectors | python3 -m json.tool
```

```bash
curl http://localhost:8083/connectors/src-mariadb/status
curl http://localhost:8083/connectors/postgres-source/status
curl http://localhost:8083/connectors/mysql-source/status
curl http://localhost:8083/connectors/sink-mariadb-to-postgres/status
curl http://localhost:8083/connectors/sink-postgres-to-mysql/status
curl http://localhost:8083/connectors/sink-mysql-to-mariadb/status
```

Verify synced data:

```bash
docker exec -i datalake-docker-postgres psql -U postgres -c "SELECT * FROM orders;"
docker exec -i datalake-docker-mysql mysql -e "SELECT * FROM testdb.products;"
docker exec -i datalake-docker-mariadb mariadb -e "SELECT * FROM testdb.customers;"
```

## CDC Pipeline

```
MariaDB (orders) ──→ Kafka ──→ PostgreSQL (orders)
PostgreSQL (products) ──→ Kafka ──→ MySQL (products)
MySQL (customers) ──→ Kafka ──→ MariaDB (customers)
```

## Monitor

- Kafka UI: http://localhost:9091
- Debezium REST API: http://localhost:8083/connectors

## Manage Connectors

```bash
curl -X PUT http://localhost:8083/connectors/<name>/pause
curl -X PUT http://localhost:8083/connectors/<name>/resume
curl -X DELETE http://localhost:8083/connectors/<name>
```
