ARG PG_VERSION
ARG PG_TAG
ARG TS_VERSION
############################
# Build tools binaries in separate image
############################
ARG GO_VERSION=1.19.1
FROM golang:${GO_VERSION}-alpine AS tools

ARG TIMESCALEDB_TUNE_VERSION=v0.16.0
ARG TIMESCALEDB_PARALLELCOPY_VERSION=v0.5.1

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

# FROM timescale/timescaledb:latest-pg14-bitnami

# USER root

ARG PG_VERSION
RUN apt-get update && \
    apt-get install -y \
    curl \
    build-essential \
    pkg-config \
    lsb-release \
    dialog \
    apt-utils \
    vim \
    curl ca-certificates \
    gnupg \
    && apt-get clean all

RUN wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | gpg --dearmor -o /etc/apt/trusted.gpg.d/timescaledb.gpg
RUN echo "deb https://packagecloud.io/timescale/timescaledb/debian/ $(lsb_release -c -s) main" | tee /etc/apt/sources.list.d/timescaledb.list
# RUN curl -s https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh | bash
    
RUN apt-get update && apt-get install -y \
    postgresql-${PG_VERSION}-cron \
    postgresql-plpython3-${PG_VERSION} \
    timescaledb-toolkit-postgresql-${PG_VERSION} \
    && apt-get clean all

RUN echo "cron.database_name = 'postgres'" >> /var/lib/postgresql/data/postgresql.conf 
RUN echo "cron.timezone = 'Europe/Dublin'" >> /var/lib/postgresql/data/postgresql.conf
RUN sed -i "s/shared_preload_libraries = 'timescaledb'/shared_preload_libraries = 'timescaledb,pg_cron,pg_stat_statements'/g" /var/lib/postgresql/data/postgresql.conf
RUN sed -i "s/log_timezone = 'Etc\/UTC'/log_timezone = 'Europe\/Dublin'/g" /var/lib/postgresql/data/postgresql.conf
RUN sed -i "s/timezone = 'Etc\/UTC'/timezone = 'Europe\/Dublin'/g" /var/lib/postgresql/data/postgresql.conf

# RUN curl -s https://packagecloud.io/install/repositories/timescale/timescaledb/script.deb.sh | bash
################################
# timescaledb-toolkit Compoiling
################################

# RUN apt-get update && \
#     apt-get install -y \
#     pkg-config libssl-dev \
#     && apt-get clean all

# ENV PATH="/root/.cargo/bin:$PATH"
# RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 
# # --default-toolchain stable
# RUN cargo install --version '=0.10.2' --force cargo-pgrx
# RUN cargo pgrx init --pg${PG_VERSION} pg_config

# RUN git clone https://github.com/timescale/timescaledb-toolkit /timescaledb-toolkit/extension
# WORKDIR /timescaledb-toolkit/extension

# RUN cargo pgrx install --release && \
#     cargo run --manifest-path ../tools/post-install/Cargo.toml -- pg_config
