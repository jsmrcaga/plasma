# In CI this should be the "last"
# version we built
ARG PLASMA_BASE=plasma
ARG PLASMA_VERSION=latest
FROM ${PLASMA_BASE}:${PLASMA_VERSION}

ARG VERSION=v0.0.0-dev-nvidia

LABEL \
	org.opencontainers.image.authors="Jo Colina <@jsmrcaga>" \
	org.opencontainers.image.version=${VERSION} \
	org.opencontainers.image.title="plasma-nvidia"

ARG NVIDIA_DRIVER_CAPABILITIES="all"
ARG NVIDIA_VISIBLE_DEVICES="all"
ARG NVIDIA_DRIVER_VERSION="570.144"

# Configure fake display
COPY ./config/video/xorg/xorg.nvidia.conf /etc/X11/xorg.conf

# Automatically add graphic cards
# for Container toolkit env variables
ENV \
	NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES} \
	NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES} \
	NVIDIA_DRIVER_VERSION=${NVIDIA_DRIVER_VERSION}

# Copy script again in case we changed it in between images
COPY --chmod=0755 ./src/setup/nvidia /plasma/setup/nvidia

# Make sure we execute the script on startup from entrypoint
RUN mv /plasma/setup/nvidia/x.sh /plasma/init.d/nvidia-x.sh

RUN bash /plasma/setup/nvidia/nvidia.sh

ENTRYPOINT ["/plasma/init.sh"]
