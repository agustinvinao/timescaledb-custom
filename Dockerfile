ARG PG_VERSION
ARG PG_TAG
ARG TS_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.19.1
FROM golang:${GO_VERSION}-alpine AS tools

ARG TIMESCALEDB_TUNE_VERSION=v0.14.2
ARG TIMESCALEDB_PARALLELCOPY_VERSION=v0.4.0

ENV TOOLS_VERSION 0.8.1

RUN apk update && apk add --no-cache git gcc \
    && go install github.com/timescale/timescaledb-tune/cmd/timescaledb-tune@${TIMESCALEDB_TUNE_VERSION} \
    && go install github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy@${TIMESCALEDB_PARALLELCOPY_VERSION}


ARG PG_TAG
ARG PG_VERSION
FROM postgres:${PG_VERSION}${PG_TAG}
ARG OSS_ONLY

LABEL maintainer="Timescale https://www.timescale.com"

COPY docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
COPY --from=tools /go/bin/* /usr/local/bin/

ARG TS_VERSION
RUN set -ex \
    && mkdir -p /var/lib/apt/lists/partial \
    && apt-get update \
    && apt-get -y install \
            \
            build-essential \
            libssl-dev \
            git \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            cmake \
            wget \
            libkrb5-dev \
            postgresql-server-dev-${PG_MAJOR} \
    && mkdir -p /build/ \
    && git clone https://github.com/timescale/timescaledb /build/timescaledb \
    \
    # Build current version \
    && cd /build/timescaledb && rm -fr build \
    && git checkout ${TS_VERSION} \
    && ./bootstrap -DCMAKE_BUILD_TYPE=RelWithDebInfo -DREGRESS_CHECKS=OFF -DTAP_CHECKS=OFF -DGENERATE_DOWNGRADE_SCRIPT=ON -DWARNINGS_AS_ERRORS=OFF -DPROJECT_INSTALL_METHOD="docker"${OSS_ONLY} \
    && cd build && make install \
    && cd ~ \
    \
    && apt-get autoremove --purge -y \
            \
            build-essential \
            libssl-dev \
            \
            dpkg-dev \
            gcc \
            libc-dev \
            make \
            cmake \
            libkrb5-dev \
    && apt-get clean -y \
    && rm -rf \
      "${HOME}/.cache" \
        /var/lib/apt/lists/* \
        /tmp/*               \
        /var/tmp/* \
        /build \
    && sed -r -i "s/[#]*\s*(shared_preload_libraries)\s*=\s*'(.*)'/\1 = 'timescaledb,\2'/;s/,'/'/" /usr/share/postgresql/postgresql.conf.sample

ARG PG_VERSION
RUN apt-get update && \
    apt-get install -y \
    curl \
    build-essential \
    pkg-config \
    lsb-release \
    dialog \
    apt-utils \
    postgresql-plpython3-${PG_VERSION} \
    postgresql-${PG_VERSION}-cron \
    vim \
    && apt-get clean all

RUN echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list
RUN wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg


RUN apt-get update && \
    apt-get install -y \
    timescaledb-toolkit-postgresql-14 \
    && apt-get clean all

RUN echo "cron.database_name = 'postgres'" >> /var/lib/postgresql/data/postgresql.conf 
RUN echo "cron.timezone = 'Europe/Dublin'" >> /var/lib/postgresql/data/postgresql.conf
RUN sed -i "s/shared_preload_libraries = 'timescaledb'/shared_preload_libraries = 'timescaledb,pg_cron'/g" /var/lib/postgresql/data/postgresql.conf
RUN sed -i "s/log_timezone = 'Etc\/UTC'/log_timezone = 'Europe\/Dublin'/g" /var/lib/postgresql/data/postgresql.conf
RUN sed -i "s/timezone = 'Etc\/UTC'/timezone = 'Europe\/Dublin'/g" /var/lib/postgresql/data/postgresql.conf