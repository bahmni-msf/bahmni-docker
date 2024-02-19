docker stop bahmni-lite-openmrsdb-1
docker rm bahmni-lite-openmrsdb-1
docker compose up openmrsdb -d

docker exec bahmni-lite-openmrsdb-1 sh -c '
cd /etc/mysql/conf.d;
echo " ">> docker.cnf
echo "# For replication">> docker.cnf
echo "server-id = 2">> docker.cnf
echo "log_bin = /var/log/mysql/mysql-bin">> docker.cnf
echo "binlog_do_db = openmrs">> docker.cnf
echo "default_authentication_plugin = mysql_native_password">> docker.cnf
echo "sync_binlog = 1">> docker.cnf;
echo "read_only = ON">> docker.cnf;'

docker restart bahmni-lite-openmrsdb-1

mysql_root_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \";\""

until docker exec bahmni-lite-openmrsdb-1 sh -c "$mysql_root_cmd"
do
    echo "Waiting for bahmni-lite-openmrsdb-1 database connection..."
    sleep 4
done

change_master_stmt="STOP SLAVE;CHANGE MASTER TO MASTER_HOST='$MASTER_HOST',MASTER_USER='$MASTER_USER',MASTER_PASSWORD='$MASTER_PASSWORD',MASTER_LOG_FILE='$MASTER_LOG_FILE',MASTER_LOG_POS=$MASTER_LOG_POS; START SLAVE;"
change_master_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \"$change_master_stmt\""
docker exec bahmni-lite-openmrsdb-1 sh -c "$change_master_cmd"

set_sql_slave_skit_counter="STOP SLAVE;SET GLOBAL sql_slave_skip_counter = 1;START SLAVE;"
set_sql_slave_skit_counter_cmd="export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e \"$set_sql_slave_skit_counter\""
docker exec bahmni-lite-openmrsdb-1 sh -c "$set_sql_slave_skit_counter_cmd"

docker exec bahmni-lite-openmrsdb-1 sh -c "export MYSQL_PWD=\"$MYSQL_ROOT_PASSWORD\"; mysql -u $MYSQL_ROOT_USER -e 'SHOW SLAVE STATUS \G'"