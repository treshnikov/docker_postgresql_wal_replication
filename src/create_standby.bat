rem Create container for the standby db node

rem Set up container name and name of its volume
set standbyContainerName=%1
set masterContainerName=
set containerPort=
set masterContainerPort=

rem Define standbyContainerName
IF "%1"=="" (
    set standbyContainerName=p2
)

rem Define container port
if "%standbyContainerName%" == "p1" (
    set containerPort=1111
    set masterContainerPort=2222
    set masterContainerName=p2
)
if "%standbyContainerName%" == "p2" (
    set containerPort=2222
    set masterContainerPort=1111
    set masterContainerName=p1
)

rem Define volume name
set /a rand=%random% %%100000
set volumeName=volume_%rand%
echo "Create standby db in %standbyContainerName% container with volume %volumeName%"

rem Create container for the stanby node
docker rm %standbyContainerName% -f
docker volume create %volumeName%
docker run -d --name %standbyContainerName% --network=pg-cluster -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata -e PGPORT=%containerPort% -p %containerPort%:%containerPort% -v %volumeName%:/var/lib/postgresql/data pg12
timeout 3 >nul

set connstr=\"user=postgres password=postgres host=%masterContainerName% port=%masterContainerPort% sslmode=prefer sslcompression=0 gssencmode=prefer krbsrvname=postgres target_session_attrs=any\"
rem Restore DB from the master DB into direcory pgdata
docker exec %standbyContainerName% runuser -l postgres -c "/scripts/create_standby.sh %connstr% %containerPort%"
