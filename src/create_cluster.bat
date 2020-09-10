rem Create PostgreSQL DB cluster 

rem Remove old containers and unused docker volumes
docker rm p1 -f
docker rm p2 -f
docker image prune -f
docker volume prune -f
docker network rm pg-cluster

rem Build docker image with debian, postgresql12 and scripts folder
cd docker 
docker build -t pg12 .
cd ..

rem Create network 
docker network create pg-cluster

rem Setup Master
call create_master.bat

rem Setup Stanby
call create_standby.bat

rem Create demo DB
docker exec p1 bash -c "psql -U postgres -c \"create database test;\""
docker exec p1 bash -c "psql -U postgres -d test -c \"create table test (i integer);\""
docker exec p1 bash -c "psql -U postgres -d test -c \"insert into test (i) select i from generate_series(0,100000) as t(i);\""

echo Select demo data on master
docker exec p1 bash -c "psql -U postgres -d test -c \"select * from test limit 5;\""

echo Select demo data on standby
docker exec p2 bash -c "psql -U postgres -d test -c \"select * from test limit 5;\""

rem Check replication status. Wait for 1 second to let the servers synchronize.
docker exec p1 bash -c "sleep 1 && psql -U postgres -x -c \"select * from pg_stat_replication\""

rem Print cluster status
call status.bat