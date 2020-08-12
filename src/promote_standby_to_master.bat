rem Promote Standby to Master

rem Define standby container name
set p1IsStandby=""
set p2IsStandby=""
set masterContainerName=""
set standbyContainerName=""
set standbyHasFound="f"

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p1IsStandby=<out.txt

del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p2IsStandby=<out.txt
del "out.txt" >nul 2>&1

if "%p2IsStandby%" == "t" (
    echo "Container p1 is master, container p2 is standby"
    set masterContainerName=p1
    set standbyContainerName=p2
    set standbyHasFound="t"
)

if "%p1IsStandby%" == "t" (
    echo "Container p2 is master, container p1 is standby"
    set masterContainerName=p2
    set standbyContainerName=p1
    set standbyHasFound="t"
)

if "%standbyHasFound%" == "f" (
    echo "Standby DB hasn't found"
    exit /B -1
)

rem Promote standby db
echo "Stop master container (%masterContainerName%)"
docker stop %masterContainerName% -t 0

echo "Promote standby container (%standbyContainerName%)"
docker exec %standbyContainerName% bash -c "runuser -l postgres -c \"/usr/lib/postgresql/12/bin/pg_ctl promote -D /var/lib/postgresql/data/pgdata\""

echo Stop synchronous replication
docker exec %standbyContainerName% bash -c "psql -U postgres -c \"ALTER SYSTEM SET synchronous_standby_names TO ''\""
docker exec %standbyContainerName% bash -c "psql -U postgres -c \"SELECT * FROM pg_create_physical_replication_slot('_slot');\""
docker exec %standbyContainerName% bash -c "psql -U postgres -c \"select pg_reload_conf()\""
docker restart %standbyContainerName% -t 0