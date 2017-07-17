FROM alpine:3.5

# Prepare runtime
ARG ETC_DIR="/etc/genieacs-gui"
ARG CFG_DIR="${ETC_DIR}/conf.d"
ARG ENV_DIR="${ETC_DIR}/env.d"
ARG APP_DIR="/opt/genieacs-gui"
ARG APP_USER="genie"

RUN apk --update add --no-cache --virtual genie_runtime \
      nodejs ruby-bundler ruby-bigdecimal sqlite-libs tzdata \
    && mkdir -p $ETC_DIR $CFG_DIR $ENV_DIR $APP_DIR \
    && adduser ${APP_USER} -h "$APP_DIR" -D -H -g "Genie ACS"

WORKDIR $APP_DIR

# Fetch and build bundles
ARG GIT_REPO="https://github.com/zaidka/genieacs-gui"
ARG GIT_VERSION="master"

RUN apk add --no-cache --virtual __bdeps \
      build-base git libc-dev libffi-dev \
      linux-headers ruby-dev zlib-dev sqlite-dev \
    && git clone "$GIT_REPO" . \
    && git checkout "$GIT_VERSION" \
    && bundle install --no-cache --deployment \
    && apk del __bdeps

# Modify configuration file layout
RUN set -ex; \
    mkdir tmp; \
    chown -R ${APP_USER} db log tmp; \
    cd ${APP_DIR}/config; \
    for sf in *-sample.*; \
    do \
        cfg=${sf/-sample/}; \
        cp "$sf" "${CFG_DIR}/${cfg}"; \
        ln -s "${CFG_DIR}/${cfg}" "${cfg}"; \
    done; \
    cd environments; \
    for e in *; \
    do \
        mv "$e" "${ENV_DIR}"; \
        ln -s "${ENV_DIR}/$e" "$e"; \
    done;

COPY env.d $ENV_DIR

USER $APP_USER

ENV GENIEACS_API_HOST="localhost" \
    GENIEACS_API_PORT="7557" \
    RAILS_ENV="development"

# XXX move to startup script and run once RAILS_ENV is different
# from last container start?
RUN ./bin/rails db:migrate && echo "$RAILS_ENV" > tmp/last_rails_env

EXPOSE 3000

ENTRYPOINT ["bin/rails", "s", "-b", "0.0.0.0"]
