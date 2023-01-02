# Copyright (c) 2021 Tailscale Inc & AUTHORS All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

# FROM mcr.microsoft.com/vscode/devcontainers/universal:linux as builder
FROM mcr.microsoft.com/devcontainers/base:ubuntu as builder
USER root
WORKDIR /app
COPY . ./

ENV PACKERFILE=packer_1.8.5_linux_amd64.zip
RUN wget https://releases.hashicorp.com/packer/1.8.5/${PACKERFILE} && \
  unzip ${PACKERFILE} -d binaries
COPY . ./

FROM mcr.microsoft.com/devcontainers/base:ubuntu
USER root

COPY .devcontainer/tailscaled /etc/init.d/tailscaled
COPY --from=builder /app/binaries/packer /usr/bin/packer
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null \
  && curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list \
  && apt-get update \
  && apt-get install -y  tailscale --no-install-recommends \
  && chmod +x /etc/init.d/tailscaled \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
