# datalake-docker

A Docker Compose setup for various databases and data infrastructure.

## Getting Started

```bash
docker compose up -d         # Start all services (pull images)
docker compose up -d --build # Start all services (pull images + build)
docker compose stop          # Stop all services (keep containers)
docker compose start         # Restart stopped services
docker compose down          # Stop and remove containers
docker compose down -v       # Stop and remove containers and volumes (data)
```

## Services

### Databases

| Service | Version | Port | Client |
|---------|---------|-----:|--------|
| Oracle | 23ai FREE | 1521 | `sqlplus / as sysdba` |
| PostgreSQL | 18 | 5432 | `psql -U postgres` |
| MariaDB | 11.8 | 3306 | `mariadb mysql` |
| MySQL | 8.4 | 3307 | `mysql` |
| CUBRID | 11.4 | 33000 | `csql cubrid` |

### Query Engines / Search

| Service | Version | Port | Client |
|---------|---------|-----:|--------|
| Trino | 471 | 8080 | `trino` |
| Hive (Hadoop) | - | 10000 | `beeline -u jdbc:hive2://localhost:10000/` |
| Elasticsearch | 8.17.0 | 9200 | `curl http://localhost:9200` |

### Infrastructure

| Service | Version | Port | Purpose |
|---------|---------|-----:|---------|
| Hadoop | - | 8020, 50010 | HDFS |
| Zookeeper | 7.9.0 | 2181 | Kafka metadata |
| Kafka | 7.9.0 | 9092 | Message broker |
| Debezium | 3.0.0 | 8083 | CDC (Kafka Connect) |
| Kafka UI | 0.7.2 | 9091 | Kafka web UI |

For Debezium CDC setup and connector configuration, see [debezium.md](debezium.md).

## JDBC Connection

| Service | JDBC URL | ID | PW |
|---------|----------|----|----|
| Oracle | `jdbc:oracle:thin:@localhost:1521:FREE` | `system` | `manager` |
| PostgreSQL | `jdbc:postgresql://localhost:5432/postgres` | `postgres` | (none) |
| MariaDB | `jdbc:mariadb://localhost:3306/mysql` | `root` | (none) |
| MySQL | `jdbc:mysql://localhost:3307/mysql` | `root` | (none) |
| CUBRID | `jdbc:CUBRID:localhost:33000:cubrid:::` | (none) | (none) |
| Trino | `jdbc:trino://localhost:8080/` | (none) | (none) |
| Hive | `jdbc:hive2://localhost:10000/` | (none) | (none) |
| Elasticsearch | `jdbc:es://localhost:9200/` | (none) | (none) |

## Container Access

Shell access:

```bash
docker compose exec -it <service-name> bash
```

DB client access:

```bash
docker compose exec -it oracle-service sqlplus / as sysdba
docker compose exec -it postgres-service psql -U postgres
docker compose exec -it mariadb-service mariadb mysql
docker compose exec -it mysql-service mysql
docker compose exec -it cubrid-service csql cubrid
docker compose exec -it trino-service trino
docker compose exec -it hadoop-service beeline -u jdbc:hive2://localhost:10000/
```

Hadoop HDFS usage:

```bash
docker compose exec -it hadoop-service bash

# List files
hdfs dfs -ls /

# Create directory
hdfs dfs -mkdir -p /user/test

# Upload / Download
hdfs dfs -put local_file.txt /user/test/
hdfs dfs -get /user/test/local_file.txt .

# View file contents
hdfs dfs -cat /user/test/local_file.txt

# Delete
hdfs dfs -rm -r /user/test
```

## Tuning

Memory usage can be adjusted per service. See the Location column for where to change each parameter.

| Service | Parameter | Default | Performance | Location |
|---------|-----------|--------:|------------:|----------|
| Oracle | `mem_limit` | 2g (min) | 4g | `docker-compose.yml` |
| PostgreSQL | `shared_buffers` | 128MB | 1GB | `command` |
| MariaDB | `innodb-buffer-pool-size` | 128MB | 1GB | `command` |
| MariaDB | `bulk_insert_buffer_size` | 8MB | 256MB | `command` |
| MySQL | `innodb-buffer-pool-size` | 128MB | 1GB | `command` |
| MySQL | `bulk_insert_buffer_size` | 8MB | 256MB | `command` |
| Trino | `-Xmx` | 1GB | 4GB | `./etc/trino/jvm.config` |
| Hadoop | `HADOOP_HEAPSIZE` | 1024MB | 4096MB | `./etc/hadoop/hadoop-env.sh` |
| Elasticsearch | `ES_JAVA_OPTS -Xmx` | 1024MB | 2048MB | `environment` |

To apply all performance settings at once, use `docker-compose.perf.yml` as an override:

```bash
docker compose -f docker-compose.yml -f docker-compose.perf.yml up -d --build
```

## Hadoop JDBC Drivers

The Hadoop container includes JDBC drivers in `hive/lib` for connection tests via `beeline`.

| Driver | Included in Build |
|--------|:-----------------:|
| PostgreSQL (`postgresql-42.5.0.jar`) | O |
| MariaDB (`mariadb-java-client-3.5.3.jar`) | O |
| MySQL (`mysql-connector-j-8.4.0.jar`) | O |
| CUBRID (`JDBC-11.3.1.0050-cubrid.jar`) | O |
| Oracle (`ojdbc8.jar`) | X (license) |

Trino and Elasticsearch JDBC drivers require Java 11+, which is incompatible with the Hadoop container (Java 8).

Oracle JDBC driver (`ojdbc8.jar`) is excluded from the build due to licensing restrictions. After starting all containers, copy it directly:

```bash
docker cp datalake-docker-oracle:/opt/oracle/product/26ai/dbhomeFree/jdbc/lib/ojdbc8.jar ojdbc8.jar
docker cp ojdbc8.jar datalake-docker-hadoop:/home/hadoop/hive/lib/ojdbc8.jar
rm ojdbc8.jar
```

## Notes

- Oracle image requires signing up at [container-registry.oracle.com](https://container-registry.oracle.com), generating an auth token, then running `docker login container-registry.oracle.com`
