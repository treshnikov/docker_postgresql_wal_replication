rem Create container for the standby db node

rem Set up container name and name of its volume
set containerName=%1
set containerPort=
set masterIpAddress=%2

rem Define containerName
IF "%1"=="" (
    set containerName=p2
)

rem Define IP address of the another (master) container
IF "%masterIpAddress%" == "" (
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
)
echo "Master IP address is %masterIpAddress%"

rem Define volume name
set /a rand=%random% %%100000
set volumeName=volume_%rand%
echo "Create standby db in %containerName% container with volume %volumeName%"

rem Create container for the stanby node
docker rm %containerName% -f
docker volume create %volumeName%
docker run -d --name %containerName% -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata -p %containerPort%:5432 -v %volumeName%:/var/lib/postgresql/data pg12

rem Restore DB from the master DB into direcory pgdata2
docker exec %containerName% /scripts/create_standby.sh %masterIpAddress% 

rem Recreate container and aim PostgreSQL PGDATA to /var/lib/postgresql/data/pgdata2 folder
rem NOTE: This trick is required only using Docker containers. There is no option to stop PostgreSQL service in a container and replace the PGDATA folder because after PostgreSQL service is stopped the container is stopped as well  
docker stop -t 0 %containerName%
docker rm %containerName% -f
docker run -d --name %containerName% -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata2 -p %containerPort%:5432 -v %volumeName%:/var/lib/postgresql/data pg12 && docker exec %containerName% bash -c "chown -R postgres:postgres /var/lib/postgresql/data/pgdata2 && rm -rf /var/lib/postgresql/data/pgdata"

