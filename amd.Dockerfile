# In CI this should be the "last"
# version we built
ARG PLASMA_BASE=plasma
ARG PLASMA_VERSION=latest
FROM ${PLASMA_BASE}:${PLASMA_VERSION}

ARG VERSION=v0.0.0-dev-amd

LABEL \
	org.opencontainers.image.authors="Jo Colina <@jsmrcaga>" \
	org.opencontainers.image.version=${VERSION} \
	org.opencontainers.image.title="plasma-amd"

ARG AMD_GCN_VERSION=4.0
ENV AMD_GCN_VERSION=$AMD_GCN_VERSION

# AMD Cloud uses Virtio
ARG USE_VIRTIO_DRIVERS=no
ENV USE_VIRTIO_DRIVERS=$USE_VIRTIO_DRIVERS

# Copy xorg configs before
COPY ./config/video/xorg/xorg.amdgpu.conf /plasma/config/amd/xorg.amdgpu.conf
COPY ./config/video/xorg/xorg.radeon.conf /plasma/config/amd/xorg.radeon.conf
COPY ./config/video/xorg/xorg.virtio.conf /plasma/config/amd/xorg.virtio.conf

# Install drivers
COPY --chmod=0755 ./src/setup/amd /plasma/setup/amd
RUN bash /plasma/setup/amd/amd.sh

# Run glmark2 to prime GPU
ENV GPU_PRIME=yes
