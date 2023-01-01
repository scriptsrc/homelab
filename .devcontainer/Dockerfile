# Copyright (c) 2021 Tailscale Inc & AUTHORS All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# FROM mcr.microsoft.com/vscode/devcontainers/universal:linux as builder
FROM mcr.microsoft.com/devcontainers/base:ubuntu as builder
USER root
WORKDIR /app
COPY . ./

ENV TSFILE=tailscale_1.26.1_amd64.tgz
RUN mkdir -p binaries && \
  wget https://pkgs.tailscale.com/stable/${TSFILE} && \
  tar xzf ${TSFILE} --strip-components=1 -C binaries
COPY . ./

ENV PACKERFILE=packer_1.8.5_linux_amd64.zip
RUN wget https://releases.hashicorp.com/packer/1.8.5/${PACKERFILE} && \
  unzip ${PACKERFILE} -d binaries
COPY . ./

FROM mcr.microsoft.com/devcontainers/base:ubuntu
USER root

COPY tailscaled /etc/init.d/tailscaled
COPY --from=builder /app/binaries/tailscaled /usr/sbin/tailscaled
COPY --from=builder /app/binaries/tailscale /usr/bin/tailscale
COPY --from=builder /app/binaries/packer /usr/bin/packer
RUN apt-get update \
  && apt-get install -y curl gpg dnsutils --no-install-recommends \
  && chmod +x /etc/init.d/tailscaled \
  && mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
