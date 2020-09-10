@echo off
rem Update synchronous_standby_names in accordance of DB cluster nodes statuses

set p1IsStandby=""
set p2IsStandby=""

del "out.txt" >nul 2>&1
docker exec p1 bash -c "psql -U postgres -p 1111 -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p1IsStandby=<out.txt

del "out.txt" >nul 2>&1
docker exec p2 bash -c "psql -U postgres -p 2222 -qtAX -c \"SELECT pg_is_in_recovery()\"">>out.txt
set /p p2IsStandby=<out.txt
del "out.txt" >nul 2>&1

echo p1IsStandby = %p1IsStandby%
echo p2IsStandby = %p2IsStandby%
set stat = %p1IsStandby%%p2IsStandby%
echo %stat%

if "%p1IsStandby%" == "f" if "%p2IsStandby%" == "t" (
    echo "p1 is master and p2 is standby, set p1.synchronous_standby_names to *"
    docker exec p1 bash -c "psql -U postgres -p 1111 -c \"ALTER SYSTEM SET synchronous_standby_names TO '*'\""
    docker exec p1 bash -c "psql -U postgres -p 1111 -c 'select pg_reload_conf()'
)

if "%p1IsStandby%" == "t" if "%p2IsStandby%" == "f" (
    echo "p2 is master and p1 is standby, set p2.synchronous_standby_names to '*'"
    docker exec p2 bash -c "psql -U postgres -p 2222 -c \"ALTER SYSTEM SET synchronous_standby_names TO '*'\""
    docker exec p2 bash -c "psql -U postgres -p 2222 -c 'select pg_reload_conf()'
)

if "%p1IsStandby%" == "f" if %p2IsStandby% == "" (
    echo "p1 is master and p2 is down, set p1.synchronous_standby_names to ''"
    docker exec p1 bash -c "psql -U postgres -p 1111 -c \"ALTER SYSTEM SET synchronous_standby_names TO ''\""
    docker exec p1 bash -c "psql -U postgres -p 1111 -c 'select pg_reload_conf()'
)

if %p1IsStandby% == "" if "%p2IsStandby%" == "f" (
    echo "p2 is master and p1 is down, set p2.synchronous_standby_names to ''"
    docker exec p2 bash -c "psql -U postgres -p 2222 -c \"ALTER SYSTEM SET synchronous_standby_names TO ''\""
    docker exec p2 bash -c "psql -U postgres -p 2222 -c 'select pg_reload_conf()'
)
@echo on