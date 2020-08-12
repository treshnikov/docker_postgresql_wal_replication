rem Create container for the standby db node

rem Set up container name and name of its volume
set containerName=%1
set containerPort=2222
IF "%1"=="" (
    set containerName=p2
)
set /a rand=%random% %%100000
set volumeName=volume_%rand%
echo "Create standby db in %containerName% container with volume %volumeName%"

rem Define IP address of the another (master) container
del "out.txt" >nul 2>&1
if "%containerName%" == "p1" (
    docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" p2 >> out.txt
    set containerPort=1111
)
if "%containerName%" == "p2" (
    docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" p1 >> out.txt
    set containerPort=2222
)
set /p masterIpAddress=<out.txt
del "out.txt" >nul 2>&1
echo "Master IP address is %masterIpAddress%"

rem Create container for the stanby node
docker rm %containerName% -f
docker volume create %volumeName%
docker run -d --name %containerName% -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata -p %containerPort%:5432 -v %volumeName%:/var/lib/postgresql/data postgres

rem Restore DB from the master DB into temporary direcory pgdata2
rem NOTE: For production use a separate user and role for replication, on the master node apply CREATE USER REPLICATION_USER WITH REPLICATION ENCRYPTED PASSWORD 'REPLICATION_PWD' and then use this user for the following command with -W parameter which will request a password to approve replication
docker exec %containerName% bash -c "pg_basebackup -D /var/lib/postgresql/data/pgdata2 -d postgresql://postgres:postgres@%masterIpAddress%:5432 -X stream -c fast -R"
docker stop -t 0 %containerName% 

rem Replace pgdata folder by using another container. One doesn't simply replace pgdata folder in the initial container, because process of PostgreSQL locks this directory.
docker run --rm -v %volumeName%:/var/lib/postgresql/data debian:buster-slim bash -c "cd /var/lib/postgresql/data && rm -rf pgdata && mv pgdata2/ pgdata/"

rem Starting container and set permissions for pgdata folder while PostgreSQL is warming up
docker start %containerName% && docker exec %containerName% bash -c "chown -R postgres:postgres /var/lib/postgresql/data/pgdata"