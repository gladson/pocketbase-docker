FROM --platform=${BUILDPLATFORM} alpine:3.18

ARG TARGETPLATFORM
ARG TARGETARCH=${TARGETARCH}
ARG TARGETOS=${TARGETOS}
ARG TARGETVARIANT=${TARGETVARIANT}

ARG BUILDPLATFORM=${BUILDPLATFORM}

ARG TZ=UTC

ARG PB_VERSION=0.17.0
ARG PB_ENCRYPTION_KEY
ARG PB_DEBUG
ARG PB_HOST=0.0.0.0
ARG PB_PORT=8181
ARG PB_CORS
ARG PB_DATA_DIR=/pb_data/database
ARG PB_MIGRATION_DIR=/pb_data/pb_migrations
ARG PB_HOOKS_DIR=/pb_data/pb_hooks
ARG PB_PUBLIC_DIR=/pb_data/pb_public
ARG PB_ULIMIT_OPEN_FILES=1024

ENV TZ="${TZ:-UTC}"

ENV POCKETBASE_VERSION="${PB_VERSION:-0.17.0}" \
    POCKETBASE_ENCRYPTION_KEY="${PB_ENCRYPTION_KEY}" \
    POCKETBASE_DATA_DIR="${PB_DATA_DIR:-/pb_data/database}" \
    POCKETBASE_MIGRATION_DIR="${PB_MIGRATION_DIR:-/pb_data/pb_migrations}" \
    POCKETBASE_HOOKS_DIR="${PB_HOOKS_DIR:-/pb_data/pb_hooks}" \
    POCKETBASE_PUBLIC_DIR="${PB_PUBLIC_DIR:-/pb_data/pb_public}" \
    POCKETBASE_DEBUG="${PB_DEBUG}" \
    POCKETBASE_HOST="${PB_HOST}" \
    POCKETBASE_PORT="${PB_PORT}" \
    POCKETBASE_CORS="${PB_CORS}" \
    POCKETBASE_ULIMIT_OPEN_FILES="${PB_ULIMIT_OPEN_FILES:-1024}"

RUN POCKETBASE_ENCRYPTION_KEY="$(echo -n $RANDOM | sha1sum | awk '{print $1}')"
RUN export POCKETBASE_ENCRYPTION_KEY
RUN echo "WARNING: POCKETBASE ENCRYPTION_KEY variable was not set or was not string!"
RUN echo "Secret key was automatically generated: ${POCKETBASE_ENCRYPTION_KEY}"
RUN echo "Please note down this value and set the POCKETBASE_ENCRYPTION_KEY within your deployment to avoid loosing access to your data!"

ENV PB_RELEASE_URL=https://github.com/pocketbase/pocketbase/releases/download

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    wget ${PB_RELEASE_URL}/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip -O /tmp/pocketbase.zip ; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
    wget ${PB_RELEASE_URL}/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_arm64.zip -O /tmp/pocketbase.zip ; \
    elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
    wget ${PB_RELEASE_URL}/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_armv7.zip -O /tmp/pocketbase.zip ; \
    elif [ "$TARGETPLATFORM" = "linux/arm/v6" ]; then \
    wget ${PB_RELEASE_URL}/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_arm64.zip -O /tmp/pocketbase.zip ; \
    elif [ "$TARGETPLATFORM" = "darwin/amd64" ]; then \
    wget ${PB_RELEASE_URL}/v${PB_VERSION}/pocketbase_${PB_VERSION}_darwin_amd64.zip -O /tmp/pocketbase.zip ; \
    fi

RUN apk update && apk --no-cache --upgrade add tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

RUN apk add --no-cache \
    ca-certificates \
    unzip \
    wget \
    zip \
    zlib-dev \
    bash

RUN mkdir -p /tmp/pocketbase \
    && cd /tmp && unzip /tmp/pocketbase.zip -d /tmp/pocketbase \
    && cp /tmp/pocketbase/pocketbase /usr/bin/pocketbase \
    && rm -rf /tmp/pocketbase /tmp/pocketbase.zip \
    && chmod +x /usr/bin/pocketbase

RUN mkdir pb_data

RUN echo "ulimit open files => $PB_ULIMIT_OPEN_FILES"
RUN ulimit -n ${PB_ULIMIT_OPEN_FILES}

EXPOSE ${PB_PORT}

ENTRYPOINT pocketbase serve --http=${POCKETBASE_HOST}:${POCKETBASE_PORT} --encryptionEnv=${POCKETBASE_ENCRYPTION_KEY} --dir=${POCKETBASE_DATA_DIR} --migrationsDir=${POCKETBASE_MIGRATION_DIR} --hooksDir=${POCKETBASE_HOOKS_DIR} --publicDir=${POCKETBASE_PUBLIC_DIR} 
