#!/bin/bash
# You need to call this script with "runuser -l postgres", 
# this is required to start the process as user postgres.

args=("$@")
port=${args[0]}

# Modify pg_hba.conf to let servers connect to each others
echo "host replication all samenet md5" >> /var/lib/postgresql/data/pgdata/pg_hba.conf 

# Let the server accept external connections (waiting for 5 seconds to let the main server start).
sleep 5 && psql -U postgres -p $port -c "ALTER SYSTEM SET listen_addresses TO '*'"

# Setting up synchronous_commit options to 'remote_apply' to have strong guaranties that transactions won't be lost.
# To get more details about synchronous_commit see https://postgrespro.com/docs/postgresql/12/runtime-config-replication and https://www.cybertec-postgresql.com/en/the-synchronous_commit-parameter
psql -U postgres -p $port -c "ALTER SYSTEM SET synchronous_commit TO 'remote_apply'"

# Creat a slot for the replication. For more information read an article https://severalnines.com/database-blog/using-postgresql-replication-slots
psql -U postgres -p $port -c "SELECT * FROM pg_create_physical_replication_slot('__slot');"

# Specifies a list of standby servers that can support synchronous replication. This attribute should be set in '' in case the standby server is down to let the main server keep working. In case the standby server is down and this attribute is equal '*' - the transaction on the main server will freeze (as well as a client app that sent this transaction) until the standby server accept this transaction.
psql -U postgres -p $port -c "ALTER SYSTEM SET synchronous_standby_names TO '*'"
psql -U postgres -p $port -c "ALTER SYSTEM SET wal_level TO 'replica'"
psql -U postgres -p $port -c "ALTER SYSTEM SET wal_log_hints TO 'on'"
psql -U postgres -p $port -c "ALTER SYSTEM SET max_wal_senders TO '10'"
psql -U postgres -p $port -c "ALTER SYSTEM SET wal_keep_segments TO '4'"
psql -U postgres -p $port -c "ALTER SYSTEM SET hot_standby TO 'on'"
psql -U postgres -p $port -c "SELECT pg_reload_conf()"

