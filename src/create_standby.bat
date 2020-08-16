 @@ -1,47 +1,41 @@
rem Create container for the standby db node

rem Set up container name and name of its volume
set standbyContainerName=%1
set masterContainerName=
set containerPort=

rem Define standbyContainerName
IF "%1"=="" (
    set standbyContainerName=p2
)

rem Define container port
if "%standbyContainerName%" == "p1" (
    set containerPort=1111
    set masterContainerName=p2
)
if "%standbyContainerName%" == "p2" (
    set containerPort=2222
    set masterContainerName=p1
)

rem Define volume name
set /a rand=%random% %%100000
set volumeName=volume_%rand%
echo "Create standby db in %standbyContainerName% container with volume %volumeName%"

rem Create container for the stanby node
docker rm %standbyContainerName% -f
docker volume create %volumeName%
docker run -d --name %standbyContainerName% --network=pg-cluster -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata -p %containerPort%:5432 -v %volumeName%:/var/lib/postgresql/data pg12

rem Restore DB from the master DB into direcory pgdata2
docker exec %standbyContainerName% /scripts/create_standby.sh %masterContainerName% 

rem Recreate container and aim PostgreSQL PGDATA to /var/lib/postgresql/data/pgdata2 folder
rem NOTE: This trick is required only using Docker containers. There is no option to stop PostgreSQL service in a container and replace the PGDATA folder because after PostgreSQL service is stopped the container is stopped as well  
docker stop -t 0 %standbyContainerName%
docker rm %standbyContainerName% -f
docker run -d --name %standbyContainerName% --network=pg-cluster -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata2 -p %containerPort%:5432 -v %volumeName%:/var/lib/postgresql/data pg12 && docker exec %standbyContainerName% bash -c "chown -R postgres:postgres /var/lib/postgresql/data/pgdata2 && rm -rf /var/lib/postgresql/data/pgdata"

