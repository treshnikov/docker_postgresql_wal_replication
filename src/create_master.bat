rem Create container for the master db node

rem Set up container and its volume
set /a rand=%random% %%100000
set volumeName=volume_%rand%
docker volume create %volumeName%
docker run -d --name p1 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata -p 1111:5432 -v %volumeName%:/var/lib/postgresql/data postgres

rem Modify pg_hba.conf to let servers connect to each others
docker exec p1 bash -c "echo \"host replication all samenet md5\" >> /var/lib/postgresql/data/pgdata/pg_hba.conf" 

rem Let the server accept external connections (waiting for 5 seconds to let the main server start).
docker exec p1 bash -c "sleep 5 && psql -U postgres -c \"ALTER SYSTEM SET listen_addresses TO '*'\""

rem Setting up synchronous_commit options to 'remote_apply' to have strong guaranties that transactions won't be lost.
rem To get more details about synchronous_commit see https://postgrespro.com/docs/postgresql/12/runtime-config-replication and https://www.cybertec-postgresql.com/en/the-synchronous_commit-parameter
docker exec p1 bash -c "psql -U postgres -c \"ALTER SYSTEM SET synchronous_commit TO 'remote_apply'\""

rem Creat a slot for the replication. For more information read an article https://severalnines.com/database-blog/using-postgresql-replication-slots
docker exec p1 bash -c "psql -U postgres -c \"SELECT * FROM pg_create_physical_replication_slot('_slot');\""
docker exec p1 bash -c "psql -U postgres -c \"ALTER SYSTEM SET primary_slot_name TO '_slot'\""

rem Specifies a list of standby servers that can support synchronous replication. This attribute should be set in '' in case the standby server is down to let the main server keep working. In case the standby server is down and this attribute is equal '*' - the transaction on the main server will freeze (as well as a client app that sent this transaction) until the standby server accept this transaction.
docker exec p1 bash -c "psql -U postgres -c \"ALTER SYSTEM SET synchronous_standby_names TO '*'\""
docker exec p1 bash -c "psql -U postgres -c \"ALTER SYSTEM SET wal_level TO 'replica'\""
docker exec p1 bash -c "psql -U postgres -c \"ALTER SYSTEM SET wal_log_hints TO 'on'\""
docker exec p1 bash -c "psql -U postgres -c \"ALTER SYSTEM SET max_wal_senders TO '10'\""
docker exec p1 bash -c "psql -U postgres -c \"ALTER SYSTEM SET wal_keep_segments TO '4'\""
docker exec p1 bash -c "psql -U postgres -c \"ALTER SYSTEM SET hot_standby TO 'on'\""
docker exec p1 bash -c "psql -U postgres -c \"select pg_reload_conf()\""
docker restart p1
