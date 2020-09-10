rem Promote Standby to Master

rem Define standby container name
set p1IsStandby=""
set p2IsStandby=""
set masterContainerName=""
set standbyContainerName=""
set standbyHasFound="f"
set standbyContainerPort=

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -p 1111 -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p1IsStandby=<out.txt 

del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -p 2222 -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p2IsStandby=<out.txt
del "out.txt" >nul 2>&1

if "%p2IsStandby%" == "t" (
    echo "Container p1 is master, container p2 is standby"
    set masterContainerName=p1
    set standbyContainerName=p2
    set standbyHasFound="t"
    set standbyContainerPort=2222
)

if "%p1IsStandby%" == "t" (
    echo "Container p2 is master, container p1 is standby"
    set masterContainerName=p2
    set standbyContainerName=p1
    set standbyHasFound="t"
    set standbyContainerPort=1111
)

if "%standbyHasFound%" == "f" (
    echo "Standby DB hasn't found"
    exit /B -1
)

echo "Stop master container (%masterContainerName%)"
docker stop %masterContainerName% -t 0

rem Promote standby db
docker exec %standbyContainerName% runuser -l postgres -c "/scripts/promote_standby_to_master.sh %standbyContainerPort%"