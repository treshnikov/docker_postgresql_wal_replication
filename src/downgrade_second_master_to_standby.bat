rem Downgrade Second master db to standby

set masterContainerName=""
set standbyContainerName=""

rem Get DBs states
rem ==========================================================
set p1IsStandby=""
set p2IsStandby=""
set masterServersCount=0

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p1IsStandby=<out.txt

del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p2IsStandby=<out.txt
del "out.txt" >nul 2>&1

if "%p2IsStandby%" == "f" (
    set /a masterServersCount=masterServersCount+1
)

if "%p1IsStandby%" == "f" (
    set /a masterServersCount=masterServersCount+1
)

echo "Detected %masterServersCount% servers which work as master"

if "%masterServersCount%" neq "2" (
    exit /B -1
)

rem Get DBs sizes of DBs to define the biggest DB
rem ==========================================================
set db1Size=
set db2Size=

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"SELECT SUM(pg_database_size(pg_database.datname)) FROM pg_database\"">>out.txt
set /p db1Size=<out.txt

del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"SELECT SUM(pg_database_size(pg_database.datname)) FROM pg_database\"">>out.txt
set /p db2Size=<out.txt
del "out.txt" >nul 2>&1

echo db1Size = %db1Size%
echo db2Size = %db2Size%

if "%db1Size%" GTR "%db2Size%" (
    echo "DB1 is bigger than DB2"
    set masterContainerName=p1
    set standbyContainerName=p2
)

if "%db1Size%" LSS "%db2Size%" (
    echo "DB2 is bigger than DB1"
    set masterContainerName=p2
    set standbyContainerName=p1
)

if "%db2Size%" EQU "%db1Size%" (
    echo "DB1 and DB2 are equal"
    set masterContainerName=p2
    set standbyContainerName=p1
)

echo "Supposed master is %masterContainerName% and supposed standby is %standbyContainerName%"

rem Restore master node as standby
rem ==========================================================
call create_standby.bat %standbyContainerName%

rem Start synchronous replication
docker exec %masterContainerName% bash -c "psql -U postgres -c \"ALTER SYSTEM SET synchronous_standby_names TO '*'\""
docker exec %masterContainerName% bash -c "psql -U postgres -c \"SELECT * FROM pg_create_physical_replication_slot('_slot');\""
docker exec %masterContainerName% bash -c "psql -U postgres -c \"select pg_reload_conf()\""
