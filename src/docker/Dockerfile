FROM postgres

RUN apt update && apt install -y dos2unix
COPY scripts/ scripts/
RUN dos2unix /scripts/create_master.sh
RUN dos2unix /scripts/create_standby.sh
RUN dos2unix /scripts/promote_standby_to_master.sh
