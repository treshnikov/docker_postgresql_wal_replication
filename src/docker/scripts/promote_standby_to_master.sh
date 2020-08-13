#!/bin/bash

# Promote standby db
runuser -l postgres -c "/usr/lib/postgresql/12/bin/pg_ctl promote -D /var/lib/postgresql/data/pgdata2"

# Set up synchronous replication
psql -U postgres -c "ALTER SYSTEM SET synchronous_standby_names TO ''"
psql -U postgres -c "SELECT * FROM pg_create_physical_replication_slot('__slot');"
psql -U postgres -c "SELECT pg_reload_conf()"
