#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE DATABASE kaizen_brain_development;
  \connect kaizen_brain_development;
  CREATE EXTENSION timescaledb_toolkit;
  CREATE EXTENSION plpython3u;
  CREATE EXTENSION pg_stat_statements;
  CREATE EXTENSION moddatetime;
EOSQL