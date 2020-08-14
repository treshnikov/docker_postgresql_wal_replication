FROM postgres

RUN apt update && apt install -y dos2unix
COPY scripts/ scripts/
RUN  find /scripts -type f -print0 | xargs -0 dos2unix