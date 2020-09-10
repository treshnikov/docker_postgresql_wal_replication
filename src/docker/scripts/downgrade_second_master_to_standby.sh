#!/bin/bash
# You need to call this script with "runuser -l postgres", 
# this is required to start the process as user postgres.

# success replication status
success_replication_status="streaming"

# connection string to master
connstr="$1"
port=$2

/usr/lib/postgresql/12/bin/pg_ctl stop -D /var/lib/postgresql/data/pgdata
/usr/lib/postgresql/12/bin/pg_rewind --target-pgdata="/var/lib/postgresql/data/pgdata" --source-server="$connstr"
touch /var/lib/postgresql/data/pgdata/standby.signal
echo "primary_conninfo = '$connstr'" >> /var/lib/postgresql/data/pgdata/postgresql.auto.conf
/usr/lib/postgresql/12/bin/pg_ctl start -o "-p $port" -D /var/lib/postgresql/data/pgdata

# wait start replication
sleep 5

replication_state=$(psql -U postgres -p $port -qtAX -c "SELECT status FROM pg_stat_wal_receiver")

# Check replication status
if [ "$replication_state" = "$success_replication_status" ]
then
    echo Replication works. Replication status = "$success_replication_status"
else
    echo Replication does not work. Replication status = "$replication_state". Make base backup.
    /scripts/create_standby.sh "$connstr" $port
fi
