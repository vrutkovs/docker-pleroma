FROM quay.io/official-images/elixir:1.13.1-alpine

ARG PLEROMA_VER=2.4.2
ENV UID=911 GID=911 MIX_ENV=prod

ENV MIX_ENV=prod

RUN echo "http://nl.alpinelinux.org/alpine/latest-stable/community" >> /etc/apk/repositories \
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

RUN git clone -b v2.4.2 https://git.pleroma.social/pleroma/pleroma.git /pleroma \
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
    wget -O soapbox-fe.zip https://gitlab.com/soapbox-pub/soapbox-fe/-/jobs/artifacts/v1.3.0/download?job=build-production && \
    unzip soapbox-fe.zip -o -d /pleroma/priv

COPY ./config.exs /etc/pleroma/config.exs

EXPOSE 4000

ENTRYPOINT ["/pleroma/docker-entrypoint.sh"]
