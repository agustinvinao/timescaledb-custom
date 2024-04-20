Dockerfile with 

About Debian based timescaledb image
Docker.debian file can be used to create a Debian based timescaledb image. Created images will be based on official debian based postgresql images.

For an image based on PG 13.9-bullesye image:

```bash
docker build -t timescaledb:2.14.2-pg14-bullseye --build-arg PG_TAG=14-bullseye --build-arg TS_VERSION=2.14.2 -f Dockerfile .
```


docker exec -it <mycontainer> bash

# plpython3
```sql
CREATE EXTENSION plpython3u;
```

# pg_cron
```sql
CREATE EXTENSION pg_cron;

```

```sql
CREATE EXTENSION jsonb_plpython3u;
CREATE EXTENSION timescaledb_toolkit;
CREATE EXTENSION pg_cron;
CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION moddatetime;
CREATE EXTENSION plpython3u;
```

```sql
show config_file;
select * from pg_extension;
```

# needs to run on each DB
```sql
CREATE EXTENSION timescaledb_toolkit;
CREATE EXTENSION plpython3u;
select * from pg_language;
CREATE EXTENSION pg_stat_statements;
CREATE EXTENSION moddatetime;
```

```conf
cron.database_name = 'postgres'
cron.timezone = 'PRC'
```


# COPY postgresql.conf.sample /usr/share/postgresql/${PG_TAG}/postgresql.conf
# RUN psql -U postgres -d postgres -c "alter user postgres with password '${POSTGRES_PASSWORD}';" && \
# RUN psql -U postgres -d postgres -c "alter system set listen_addresses to '*';" && \
# RUN psql -U postgres -d postgres -c "alter system set shared_preload_libraries to 'timescaledb';"   


# performance

https://blog.rustprooflabs.com/2019/04/postgresql-pgbench-raspberry-pi



intarray
tablefunc
pg_partman
pgvector




https://github.com/dhamaniasad/awesome-postgres

https://medium.com/dandelion-tutorials/how-to-fix-chown-permission-denied-issue-when-using-colima-on-mac-os-x-d925e420c875