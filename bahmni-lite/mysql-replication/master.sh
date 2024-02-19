docker stop bahmni-lite-openmrsdb-1
docker rm bahmni-lite-openmrsdb-1
docker compose up openmrsdb -d

docker exec bahmni-lite-openmrsdb-1 sh -c '
cd /etc/mysql/conf.d;
echo " ">> docker.cnf
echo "# For replication">> docker.cnf
echo "server-id = 1">> docker.cnf;
echo "log_bin = /var/log/mysql/mysql-bin">> docker.cnf;
echo "log-bin-index = /var/log/mysql/mysql-bin.index">> docker.cnf;
echo "binlog_format = ROW">> docker.cnf;
echo "binlog_do_db = openmrs">> docker.cnf;
echo "expire_logs_days = 90">> docker.cnf;
echo "max_binlog_size = 100M">> docker.cnf;
echo "innodb_flush_log_at_trx_commit = 1">> docker.cnf;
echo "sync_binlog = 1">> docker.cnf;
echo "default_authentication_plugin = mysql_native_password">> docker.cnf;'

docker restart bahmni-lite-openmrsdb-1

until docker exec bahmni-lite-openmrsdb-1 sh -c "export MYSQL_PWD=$MYSQL_ROOT_PASSWORD; mysql -u root -e ';'"
do
    echo "Waiting for bahmni-lite-openmrsdb-1 database connection..."
    sleep 4
done

create_slave_user="delete from mysql.user where User='$MYSQL_SLAVE_USER';FLUSH PRIVILEGES;CREATE USER '$MYSQL_SLAVE_USER'@'%' IDENTIFIED BY '$MYSQL_SLAVE_PASSWORD'; GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_SLAVE_USER'@'%'; FLUSH PRIVILEGES; SHOW MASTER STATUS \\G;"

create_slave_user_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \"$create_slave_user\""

docker exec bahmni-lite-openmrsdb-1 sh -c "$create_slave_user_cmd"