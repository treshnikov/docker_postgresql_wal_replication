# PostgreSQL DB cluster in Docker containers
## Overview
This repository provides a set of useful scripts that allow you to set up and manage PostgreSQL DB cluster with WAL streaming replication using PostgreSQL slots under the Windows operating system. These scripts are only supposed to be used for testing and development purposes.
- The cluster includes two Docker containers - p1 and p2.
- Each container publishes a PostgreSQL database that can be reached at localhost: 1111 and localhost: 2222 respectively.
- Data folder of the DB is located at `/var/lib/postgresql/data/pgdata/` directory. This directory can be assigned to a Docker volume.

![](https://github.com/treshnikov/postgresql_wal_replication/blob/master/img/demo.png)
## How to use
- Use `create_cluster.bat` to create containers. After the cluster is created container p1 will be defined as a master and p2 as a standby. Take in mind that this script invokes `docker volume prune -f` to drop unused volumes.
- Use `update_synchronous_standby_names_on_master.bat` if the standby server is down or it was down and appears again to let the main server keep performing transactions with or without approvement of the standby server. Otherwise, you can face the case when an incoming transaction on master DB is frozen until the standby (which is down) approves the transaction.
- Use `promote_standby_to_master.bat` to promote the standby server to master. This script automatically detects the standby node and applies commands. The container with the master DB will be stopped.
- After the promotion of the standby, you can run a container with the former master to simulate "Split-brain" case when two nodes with the status of a master are online. Use `downgrade_second_master_to_standby.bat` script which chooses one of two available DB with the biggest size and lets it keep working as a master. Another DB will be reinitialized as a standby DB.
- Use `status.bat` to print the current status of the cluster.
 # To improve
- Create and use separate user/role for replication instead of using user `postgres`.
