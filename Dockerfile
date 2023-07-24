# Copyright 2020-2021 Changkun Ou. All rights reserved.
# Use of this source code is governed by a GPL-3.0
# license that can be found in the LICENSE file.

FROM ubuntu:latest AS builder-env
WORKDIR /app
COPY . .
RUN apt update && apt install -y wget gcc
RUN mkdir -p /root/goes
ARG GOVERSION
RUN apt install -y golang git
RUN CGO_ENABLED=0 /usr/bin/go build -mod=vendor
ARG MIDGARD_DOMAIN
ARG MIDGARD_BACKUP_ENABLED
ARG MIDGARD_BACKUP_REPO
ARG MIDGARD_USER
ARG MIDGARD_PASS
RUN apt-get install gettext-base && \
  export MIDGARD_DOMAIN=$MIDGARD_DOMAIN && \
  export MIDGARD_BACKUP_ENABLED=$MIDGARD_BACKUP_ENABLED && \
  export MIDGARD_BACKUP_REPO=$MIDGARD_BACKUP_REPO && \
  export MIDGARD_USER=$MIDGARD_USER && \
  export MIDGARD_PASS=$MIDGARD_PASS && \
  envsubst < config.yml.template > config.yml

FROM chromedp/headless-shell:latest
RUN apt update && apt install -y dumb-init git
ENTRYPOINT ["dumb-init", "--"]

WORKDIR /app
COPY . .
COPY --from=builder-env /app/midgard /app/mg
COPY --from=builder-env /app/config.yml /app/config.yml
ARG SSH_PRIVATE_KEY
ARG GITUSER
ARG GITMAIL
RUN mkdir -p /root/.ssh && \
  echo "$SSH_PRIVATE_KEY" | base64 --decode > /root/.ssh/id_rsa && \
  chmod 400 /root/.ssh/id_rsa && \
  echo "StrictHostKeyChecking no" > /root/.ssh/config && \
  git config --global url."git@github.com:".insteadOf "https://github.com/" && \
  git config --global user.name $GITUSER && \
  git config --global user.email $GITMAIL
EXPOSE 80
CMD ["/app/mg", "server"]