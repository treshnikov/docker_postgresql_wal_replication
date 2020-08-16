@echo off
set p1Status=
set p1DbSize=
set p1WalSegmentsCount=
set p1PgWalSize=
set p1_synchronous_standby_names=
set p1_number_of_slots=
set p1PrimarySlotName=
set p1_primary_conninfo=

set p2Status=
set p2DbSize=
set p2WalSegmentsCount=
set p2PgWalSize=
set p2_synchronous_standby_names=
set p2_number_of_slots=
set p2PrimarySlotName=
set p2_primary_conninfo=

echo PostgreSQL cluster status
echo =========================
del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"SELECT CASE WHEN pg_is_in_recovery() = 't' THEN 'STANDBY' WHEN pg_is_in_recovery() = 'f' THEN 'MASTER' ELSE '?' END \"">>out.txt
set /p p1Status=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"SELECT CASE WHEN pg_is_in_recovery() = 't' THEN 'STANDBY' WHEN pg_is_in_recovery() = 'f' THEN 'MASTER' ELSE '?' END \"">>out.txt
set /p p2Status=<out.txt

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"show synchronous_standby_names\"">>out.txt
set /p p1_synchronous_standby_names=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"show synchronous_standby_names\"">>out.txt
set /p p2_synchronous_standby_names=<out.txt

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"show primary_conninfo\"">>out.txt
set /p p1_primary_conninfo=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"show primary_conninfo\"">>out.txt
set /p p2_primary_conninfo=<out.txt
 
del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"select count(*) from pg_replication_slots\"">>out.txt
set /p p1_number_of_slots=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"select count(*) from pg_replication_slots\"">>out.txt
set /p p2_number_of_slots=<out.txt

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"SELECT pg_size_pretty(SUM(pg_database_size(pg_database.datname))) FROM pg_database\"">>out.txt
set /p p1DbSize=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"SELECT pg_size_pretty(SUM(pg_database_size(pg_database.datname))) FROM pg_database\"">>out.txt
set /p p2DbSize=<out.txt

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"SELECT pg_size_pretty(SUM(pg_database_size(pg_database.datname))) FROM pg_database\"">>out.txt
set /p p1DbSize=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"SELECT pg_size_pretty(SUM(pg_database_size(pg_database.datname))) FROM pg_database\"">>out.txt
set /p p2DbSize=<out.txt

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"select pg_size_pretty(sum((pg_stat_file(concat('pg_wal/',fname))).size)) as total_size from pg_ls_dir('pg_wal') as t(fname);\"">>out.txt
set /p p1PgWalSize=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"select pg_size_pretty(sum((pg_stat_file(concat('pg_wal/',fname))).size)) as total_size from pg_ls_dir('pg_wal') as t(fname);\"">>out.txt
set /p p2PgWalSize=<out.txt

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"SELECT count(*) FROM pg_ls_waldir()\"">>out.txt
set /p p1WalSegmentsCount=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"SELECT count(*) FROM pg_ls_waldir()\"">>out.txt
set /p p2WalSegmentsCount=<out.txt

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"show primary_slot_name\"">>out.txt
set /p p1PrimarySlotName=<out.txt
del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"show primary_slot_name\"">>out.txt
set /p p2PrimarySlotName=<out.txt

del "out.txt" >nul 2>&1
echo Container: p1
echo Status: %p1Status%
echo DbSize: %p1DbSize%
echo Number of wal segments: %p1WalSegmentsCount%
echo Size of pg_wal directory: %p1PgWalSize%
echo synchronous_standby_names: %p1_synchronous_standby_names%
echo number_of_slots: %p1_number_of_slots%
echo primary_slot_name: %p1PrimarySlotName%
echo primary_conninfo: %p1_primary_conninfo%
echo -------------------------
echo Container: p2
echo Status: %p2Status%
echo DbSize: %p2DbSize%
echo Number of wal segments: %p2WalSegmentsCount%
echo Size of pg_wal directory: %p2PgWalSize%
echo synchronous_standby_names: %p2_synchronous_standby_names%
echo number_of_slots: %p2_number_of_slots%
echo primary_slot_name: %p2PrimarySlotName%
echo primary_conninfo: %p2_primary_conninfo%
@echo on