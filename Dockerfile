FROM lizardbyte/sunshine:v2025.426.10137-debian-bookworm

ARG VERSION=v0.0.0-dev
LABEL \
	org.opencontainers.image.authors="Jo Colina <@jsmrcaga>" \
	org.opencontainers.image.version=${VERSION} \
	org.opencontainers.image.title="plasma"

# Install deps
USER root
RUN apt-get update
RUN apt-get install x11-xserver-utils libgbm1 -y

# Install Steam
#   * Order of operations is extramely important here
#   * non-free-firmware is a small optimization for the nvidia image
RUN echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
	dpkg --add-architecture i386 && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		steam-installer \
		mesa-vulkan-drivers \
		libglx-mesa0:i386 \
		mesa-vulkan-drivers:i386 \
		libgl1-mesa-dri:i386 &&\
	# Make sure we have a steam binary ready to use
	ln -sf /usr/games/steam /usr/bin/steam

COPY ./src /plasma

ENTRYPOINT ["/plasma/init.sh"]
