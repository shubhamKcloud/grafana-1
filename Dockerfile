# Base image
FROM grafana/grafana:latest

# Environment variables
ENV GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource

# Copy custom configuration files
#COPY ./provisioning /etc/grafana/provisioning

# Expose Grafana port
EXPOSE 3000

# Start Grafana server
CMD ["grafana-server", "--homepath=/usr/share/grafana", "--config=/etc/grafana/grafana.ini", "--packaging=docker"]


# FROM node:16-alpine3.15 as js-builder

# ENV NODE_OPTIONS=--max_old_space_size=8000

# WORKDIR /grafana

# COPY package.json yarn.lock .yarnrc.yml ./
# COPY .yarn .yarn
# COPY packages packages
# COPY plugins-bundled plugins-bundled

# RUN yarn install

# COPY tsconfig.json .eslintrc .editorconfig .browserslistrc .prettierrc.js babel.config.json .linguirc ./
# COPY public public
# COPY tools tools
# COPY scripts scripts
# COPY emails emails

# ENV NODE_ENV production
# RUN yarn build

# FROM golang:1.17.6-alpine3.15 as go-builder

# RUN apk add --no-cache gcc g++ make

# WORKDIR /grafana

# COPY go.mod go.sum embed.go Makefile build.go package.json ./
# COPY cue cue
# COPY packages/grafana-schema packages/grafana-schema
# COPY public/app/plugins public/app/plugins
# COPY pkg pkg
# COPY scripts scripts
# COPY cue.mod cue.mod
# COPY .bingo .bingo

# RUN go mod verify
# RUN make build-go

# FROM debian:latest as cloudwatch-builder

# RUN apt-get update &&  \
#     apt-get install -y ca-certificates curl && \
#     rm -rf /var/lib/apt/lists/*

# RUN curl -O https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb && \
#     dpkg -i -E amazon-cloudwatch-agent.deb && \
#     rm -rf /tmp/* && \
#     rm -rf /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard && \
#     rm -rf /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl && \
#     rm -rf /opt/aws/amazon-cloudwatch-agent/bin/config-downloader

# # Final stage
# FROM alpine:3.15

# LABEL maintainer="Grafana team <hello@grafana.com>"

# ARG GF_UID="472"
# ARG GF_GID="0"

# ENV PATH="/usr/share/grafana/bin:$PATH" \
#   GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
#   GF_PATHS_DATA="/var/lib/grafana" \
#   GF_PATHS_HOME="/usr/share/grafana" \
#   GF_PATHS_LOGS="/var/log/grafana" \
#   GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
#   GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

# WORKDIR $GF_PATHS_HOME

# RUN apk add --no-cache ca-certificates bash tzdata musl-utils
# RUN apk add --no-cache openssl ncurses-libs ncurses-terminfo-base --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main
# RUN apk upgrade ncurses-libs ncurses-terminfo-base --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main
# RUN apk info -vv | sort

# COPY conf ./conf

# RUN if [ ! $(getent group "$GF_GID") ]; then \
#   addgroup -S -g $GF_GID grafana; \
#   fi

# RUN export GF_GID_NAME=$(getent group $GF_GID | cut -d':' -f1) && \
#   mkdir -p "$GF_PATHS_HOME/.aws" && \
#   adduser -S -u $GF_UID -G "$GF_GID_NAME" grafana && \
#   mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
#   "$GF_PATHS_PROVISIONING/dashboards" \
#   "$GF_PATHS_PROVISIONING/notifiers" \
#   "$GF_PATHS_PROVISIONING/plugins" \
#   "$GF_PATHS_PROVISIONING/access-control" \
#   "$GF_PATHS_LOGS" \
#   "$GF_PATHS_PLUGINS" \
#   "$GF_PATHS_DATA" && \
#   cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
#   cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
#   chown -R "grafana:$GF_GID_NAME" "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING" && \
#   chmod -R 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" "$GF_PATHS_PROVISIONING"

# COPY --from=go-builder /grafana/bin/*/grafana-server /grafana/bin/*/grafana-cli ./bin/
# COPY --from=js-builder /grafana/public ./public
# COPY --from=js-builder /grafana/tools ./tools

# EXPOSE 3000

# COPY ./packaging/docker/run.sh /run.sh

# COPY --from=cloudwatch-builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# COPY --from=cloudwatch-builder /opt/aws/amazon-cloudwatch-agent /opt/aws/amazon-cloudwatch-agent
# COPY conf/cloudwatch.json /etc/cwagentconfig
# RUN chown -R "grafana:$GF_GID_NAME" /opt/aws/amazon-cloudwatch-agent
# ENV RUN_IN_CONTAINER="True"
# RUN chown -R "grafana:$GF_GID_NAME" "/usr/share/grafana/public/img/"
# RUN chmod -R 777 "/usr/share/grafana/public/img/"

# USER grafana
# ENTRYPOINT [ "/run.sh" ]
