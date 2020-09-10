@echo off
rem Downgrade Second master db to standby

set masterContainerName=""
set standbyContainerName=""

rem Get DBs states
rem ==========================================================
set p1IsStandby=""
set p2IsStandby=""
set masterServersCount=0

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -p 1111 -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p1IsStandby=<out.txt

del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -p 2222 -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p2IsStandby=<out.txt
del "out.txt" >nul 2>&1

if "%p2IsStandby%" == "f" (
    set /a masterServersCount=masterServersCount+1
)

if "%p1IsStandby%" == "f" (
    set /a masterServersCount=masterServersCount+1
)

echo [101;93m Detected %masterServersCount% servers which work as master [0m

if "%masterServersCount%" neq "2" (
    exit /B -1
)

rem Get DBs sizes of DBs to define the biggest DB
rem ==========================================================
set db1Size=
set db2Size=
set standbyContainerPort=
set masterContainerPort=

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -p 1111 -qtAX -c \"SELECT SUM(pg_database_size(pg_database.datname)) FROM pg_database\"">>out.txt
set /p db1Size=<out.txt

del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -p 2222 -qtAX -c \"SELECT SUM(pg_database_size(pg_database.datname)) FROM pg_database\"">>out.txt
set /p db2Size=<out.txt
del "out.txt" >nul 2>&1

echo db1Size = %db1Size%
echo db2Size = %db2Size%

if %db1Size% GTR %db2Size% (
    echo [101;93m DB1 is bigger than DB2 [0m
    set masterContainerName=p1
    set standbyContainerPort=2222
    set masterContainerPort=1111
    set standbyContainerName=p2
)

if %db1Size% LSS %db2Size% (
    echo [101;93m DB2 is bigger than DB1 [0m
    set masterContainerName=p2
    set standbyContainerPort=1111
    set masterContainerPort=2222
    set standbyContainerName=p1
)

if %db2Size% EQU %db1Size% (
    echo [101;93m DB1 and DB2 are equal [0m
    set masterContainerName=p2
    set standbyContainerPort=1111
    set masterContainerPort=2222
    set standbyContainerName=p1
)

echo [101;93m Supposed master is %masterContainerName% and supposed standby is %standbyContainerName% [0m

@echo on

rem Restore master node as standby with pg_rewind
rem ==========================================================
set connstr=\"user=postgres password=postgres host=%masterContainerName% port=%masterContainerPort% sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any\"

docker exec %standbyContainerName% runuser -l postgres -c "/scripts/downgrade_second_master_to_standby.sh %connstr% %standbyContainerPort%"

rem Let the server start and update synchronous_standby_names 
call update_synchronous_standby_names_on_master.bat