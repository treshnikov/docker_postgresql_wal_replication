#!/bin/bash

args=("$@")
masterIpAddress=${args[0]}

# Restore DB from the master DB into direcory pgdata2
# NOTE: For production use a separate user and role for replication, on the master node apply CREATE USER REPLICATION_USER WITH REPLICATION ENCRYPTED PASSWORD 'REPLICATION_PWD' and then use this user for the following command with -W parameter which will request a password to approve replication
pg_basebackup -D /var/lib/postgresql/data/pgdata2 -d postgresql://postgres:postgres@$masterIpAddress:5432 -X stream -c fast -R --slot=__slot

