FROM lizardbyte/sunshine:v2025.426.10137-debian-bookworm

ARG VERSION=v0.0.0-dev
LABEL \
	org.opencontainers.image.authors="Jo Colina <@jsmrcaga>" \
	org.opencontainers.image.version=${VERSION} \
	org.opencontainers.image.title="plasma"

# Install deps
USER root
RUN apt-get update
RUN apt-get install -y \
	# X stuff
	x11-xserver-utils \
	xserver-xorg-core \
	# X input
	x11-xkb-utils \
	xbindkeys \
	xclip \
	xdotool \
	xserver-xorg-input-evdev \
	xserver-xorg-input-libinput \
	xserver-xorg-legacy \
	# libgbm1 is needed for sunshine but for some reason does not
	# come with the base sunshine image
	libgbm1 && \
	libinput-tools && \
	# Cleanup
	apt-get autoremove && \
	apt-get clean

# User/permissions config for X. Needed for all GPU types
COPY ./config/video/xorg/Xwrapper.conf /etc/X11/Xwrapper.config

# Configure display for AMD/Intel
# Full credit to Josh5
# @see https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/overlay/templates/xorg/xorg.dummy.conf
COPY ./config/video/xorg/xorg.conf /etc/X11/xorg.conf

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
		libgl1-mesa-dri:i386 && \
	apt-get autoremove && \
	apt-get clean && \
	# Make sure we have a steam binary ready to use
	ln -sf /usr/games/steam /usr/bin/steam

# Copy management scripts
COPY --chmod=0755 ./src /plasma
RUN mkdir -p /plasma/init.d /plasma/pre-hooks.d /plasma/post-hooks.d

# Allows Steam and Sunshine to run
ENV DISPLAY=:0

ENTRYPOINT ["/plasma/init.sh"]
