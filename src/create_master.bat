rem Create container for the master db node

rem Create volume
set /a rand=%random% %%100000
set volumeName=volume_%rand%
docker volume create %volumeName%

rem Create container
docker run -d --name p1 --network=pg-cluster -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=postgres -e PGDATA=/var/lib/postgresql/data/pgdata -e PGPORT=1111 -p 1111:1111 -v %volumeName%:/var/lib/postgresql/data pg12

rem Invoke create_master.sh
docker exec p1 runuser -l postgres -c "/scripts/create_master.sh 1111"