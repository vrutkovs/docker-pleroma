FROM docker.io/elixir:1.14.2-alpine

ARG PLEROMA_VER=2.4.5
ARG SOAPBOX_VER=2.0.0
ENV UID=911 GID=911 MIX_ENV=prod

ENV MIX_ENV=prod

RUN echo "http://nl.alpinelinux.org/alpine/latest-stable/main" >> /etc/apk/repositories \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/* \
    && apk update \
    && apk add git gcc g++ musl-dev make cmake file-dev \
    exiftool imagemagick libmagic ncurses postgresql-client ffmpeg

RUN addgroup -g ${GID} pleroma \
    && adduser -h /pleroma -s /bin/false -D -G pleroma -u ${UID} pleroma

ARG DATA=/var/lib/pleroma
RUN mkdir -p /etc/pleroma \
    && chown -R pleroma /etc/pleroma \
    && mkdir -p ${DATA}/uploads \
    && mkdir -p ${DATA}/static \
    && chown -R pleroma ${DATA}

USER pleroma
WORKDIR /pleroma

RUN git clone -b v${PLEROMA_VER} https://git.pleroma.social/pleroma/pleroma.git /pleroma \
    && git checkout v${PLEROMA_VER}

RUN echo "import Mix.Config" > config/prod.secret.exs \
    && mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get --only prod \
    && mkdir release \
    && mix release --path /pleroma

RUN chmod a+x /pleroma/bin/pleroma && \
    chmod a+x /pleroma/releases/${PLEROMA_VER}/elixir && \
    chmod a+w /pleroma/lib -R && \
    wget -O soapbox-fe.zip https://gitlab.com/soapbox-pub/soapbox-fe/-/jobs/artifacts/v${SOAPBOX_VER}/download?job=build-production && \
    mkdir -p ${DATA}/static/frontends/soapbox/stable && \
    unzip soapbox-fe.zip -o -d ${DATA}/static/frontends/soapbox/stable && \
    mv ${DATA}/static/frontends/soapbox/stable/static/* ${DATA}/static/frontends/soapbox/stable

COPY ./config.exs /etc/pleroma/config.exs

EXPOSE 4000

ENTRYPOINT ["/pleroma/docker-entrypoint.sh"]
