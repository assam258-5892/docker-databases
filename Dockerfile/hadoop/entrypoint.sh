#!/bin/sh

echo "[ START SSH-SERVER ]"
/usr/sbin/sshd

ssh localhost </dev/null
while [ "$?" != "0" ]; do
sleep 1
ssh localhost </dev/null
done
cp .ssh/known_hosts known_hosts
ssh-keyscan -H hadoop >>known_hosts 2>/dev/null
sort -u known_hosts >.ssh/known_hosts
rm known_hosts

if [ -d /home/hadoop/package ]; then

echo ""                                                         >>.bashrc
echo "PS1='[\u@\h \w]\$ '"                                      >>.bashrc
echo ""                                                         >>.bashrc
echo "alias beeline='beeline -u jdbc:hive2://localhost:10000/'" >>.bashrc
echo "alias remove='rm -f .*~ *~'"                              >>.bashrc

echo "[ INITIALIZE POSTGRESQL ]"
pg_ctl init -D "${PGDATA}"
echo "listen_addresses = '*'"                                                >>"${PGDATA}/postgresql.conf"
echo "unix_socket_directories = '${PGDATA}'"                                 >>"${PGDATA}/postgresql.conf"
echo "host    all             all             0.0.0.0/0               trust" >>"${PGDATA}/pg_hba.conf"
pg_ctl start -D "${PGDATA}" -l "${PGDATA}/logfile"
psql postgres -c "create database hive"

echo "[ INITIALIZE HDFS ]"
hdfs namenode -format

echo "[ START HDFS ]"
start-dfs.sh

echo "[ INITIALIZE HIVE ]"
hdfs dfs -mkdir     /tmp
hdfs dfs -mkdir -p  /user/hive/warehouse
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse
schematool -dbType postgres -initSchema

rm -rf /home/hadoop/package

else

echo "[ START POSTGRESQL ]"
rm -f "${PGDATA}/postmaster.pid" "/tmp/.s.PGSQL.${PGPORT}" "/tmp/.s.PGSQL.${PGPORT}.lock"
pg_ctl start -D "${PGDATA}" -l "${PGDATA}/logfile"

echo "[ START HDFS ]"
start-dfs.sh

fi

echo "[ START HIVE ]"
hiveserver2
echo "[ STOP HIVE ]"

echo "[ STOP HDFS ]"
stop-dfs.sh

echo "[ STOP POSTGRESQL ]"
pg_ctl stop -D "${PGDATA}" -l "${PGDATA}/logfile"

echo "[ STOP SSH-SERVER ]"
kill -TERM `pgrep -f /usr/sbin/sshd`

echo "[ DONE SHUTDOWN ]"
