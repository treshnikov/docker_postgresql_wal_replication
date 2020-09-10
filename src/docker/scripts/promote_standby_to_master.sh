#!/bin/bash
# You need to call this script with "runuser -l postgres", 
# this is required to start the process as user postgres.

args=("$@")
port=${args[0]}

# Promote standby db
/usr/lib/postgresql/12/bin/pg_ctl promote -D /var/lib/postgresql/data/pgdata

psql -U postgres -p $port -c "CHECKPOINT;"

# Set up synchronous replication
psql -U postgres -p $port -c "ALTER SYSTEM SET synchronous_standby_names TO ''"
psql -U postgres -p $port -c "SELECT * FROM pg_create_physical_replication_slot('__slot');"
psql -U postgres -p $port -c "SELECT pg_reload_conf()"

