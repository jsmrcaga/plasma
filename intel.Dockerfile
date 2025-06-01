# In CI this should be the "last"
# version we built
ARG PLASMA_BASE=plasma
ARG PLASMA_VERSION=latest
FROM ${PLASMA_BASE}:${PLASMA_VERSION}

ARG VERSION=v0.0.0-dev-intel

LABEL \
	org.opencontainers.image.authors="Jo Colina <@jsmrcaga>" \
	org.opencontainers.image.version=${VERSION} \
	org.opencontainers.image.title="plasma-intel"
