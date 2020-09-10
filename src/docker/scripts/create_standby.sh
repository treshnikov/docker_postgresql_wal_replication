#!/bin/bash
# You need to call this script with "runuser -l postgres", 
# this is required to start the process as user postgres.

args=("$@")
connstr=${args[0]}
port=${args[1]}

# Stop server
/usr/lib/postgresql/12/bin/pg_ctl stop -D /var/lib/postgresql/data/pgdata

# Remove data from database directories
rm -r /var/lib/postgresql/data/pgdata/*

# Restore DB from the master DB into direcory pgdata
# NOTE: For production use a separate user and role for replication, on the master node apply CREATE USER REPLICATION_USER WITH REPLICATION ENCRYPTED PASSWORD 'REPLICATION_PWD' and then use this user for the following command with -W parameter which will request a password to approve replication
/usr/lib/postgresql/12/bin/pg_basebackup -D /var/lib/postgresql/data/pgdata -d "$connstr" -X stream -c fast -R --slot=__slot

# Start server
/usr/lib/postgresql/12/bin/pg_ctl start -o "-p $port" -D /var/lib/postgresql/data/pgdata
