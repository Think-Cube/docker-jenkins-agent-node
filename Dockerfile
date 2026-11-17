FROM node:26.13.1-trixie-slim@sha256:e6bedef217677b276c591795e169840edd9096dbf13f29df8ef8d1856b8820bc AS node

FROM jenkins/ssh-agent:9.5.0-jdk21@sha256:78ade73b7e8ff8b5b84a016f6a1afc9f98362908bf2f43643a42c599a8f3bd1c

LABEL org.opencontainers.image.title="jenkins-agent-node" \
      org.opencontainers.image.description="Jenkins SSH build agent with Java and Node.js LTS" \
      org.opencontainers.image.vendor="Think-Cube" \
      org.opencontainers.image.authors="contact@thinkcube.dev" \
      org.opencontainers.image.licenses="MIT"

# The upgrade is what lets the weekly rebuild pick up security patches
# while the base image stays pinned by digest. Node.js needs libatomic1,
# which jenkins/ssh-agent does not ship.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libatomic1 && \
    rm -rf /var/lib/apt/lists/*

# Both images are built on Debian trixie, so the remaining libraries Node.js needs are already here.
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx && \
    ln -s ../lib/node_modules/corepack/dist/corepack.js /usr/local/bin/corepack && \
    node --version && \
    npm --version
