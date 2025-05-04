# debian:bookworm-slim
# amd64
FROM debian@sha256:4b50eb66f977b4062683ff434ef18ac191da862dbe966961bc11990cf5791a8d


ARG AUTHOR="Jo Colina <@jsmrcaga>"
ARG VERSION=v0.0.0-dev

ARG USERNAME=plasma
ARG PUID=1000
ARG PGID=1000

LABEL \
	org.opencontainers.image.authors=${AUTHOR} \
	org.opencontainers.image.version=${VERSION} \
	org.opencontainers.image.title="plasma"

ARG LOCALE=en_US.UTF-8

# Install sunshine and dependencies
USER root

RUN apt-get update && \
	apt-get install -y \
		# General
		locales \
		supervisor \
		# Sunshine
		va-driver-all \
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
		libgbm1 \
		libinput-tools && \
	# Cleanup
	apt-get autoremove && \
	apt-get clean

COPY --from=lizardbyte/sunshine:v2025.426.10137-debian-bookworm /sunshine.deb /plasma/sunshine.deb

# @see https://github.com/LizardByte/Sunshine/blob/3de3c299b23f64909bd6b3e42626ec818b0221d6/docker/debian-bookworm.dockerfile#L70
RUN apt-get install -y --no-install-recommends /plasma/sunshine.deb && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# User/permissions config for X. Needed for all GPU types
COPY ./config/video/xorg/Xwrapper.conf /etc/X11/Xwrapper.config

# Configure display for AMD/Intel
# Full credit to Josh5
# @see https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/overlay/templates/xorg/xorg.dummy.conf
COPY ./config/video/xorg/xorg.conf /etc/X11/xorg.conf

# Configure input rules
COPY ./config/input/xorg/10-evdev.conf /etc/X11/xorg.conf.d/10-evdev.conf
COPY ./config/input/udev/99-sunshine.rules /etc/udev/rules.d/99-sunshine.rules

# Install Steam
#   * Order of operations is extramely important here
#   * non-free-firmware is a small optimization for the nvidia image
RUN echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
	dpkg --add-architecture i386 && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		# @see https://developer.valvesoftware.com/wiki/Command_line_options#Steam
		steam-installer \
		dbus-x11 \
		mesa-vulkan-drivers \
		libglx-mesa0:i386 \
		# this includes libgbm.so.1 32bit, otherwise steam dies
		libgbm-dev:i386 \
		# This is needed for some operations Steam does (throws an error otherwise)
		xdg-user-dirs \
		mesa-vulkan-drivers:i386 \
		libgl1-mesa-dri:i386 && \
	apt-get autoremove && \
	apt-get clean && \
	# Make sure we have a steam binary ready to use
	ln -sf /usr/games/steam /usr/bin/steam

# Copy management scripts
COPY --chmod=0755 ./src /plasma
RUN mkdir -p /plasma/init.d /plasma/pre-hooks.d /plasma/post-hooks.d

# Handle locales
RUN /plasma/setup/locales/gen_locale.sh ${LOCALE}
ENV \
	LANGUAGE=${LOCALE} \
	LANG=${LOCALE} \
	LC_ALL=${LOCALE}

# Allows Steam and Sunshine to run
ENV DISPLAY=:0 \
	XDG_RUNTIME_DIR=/tmp/xdg-runtime \
	# Will be useful for supervisord
	USERNAME=${USERNAME}

# Setup user
RUN \
	mkdir /home/${USERNAME} && \
	# Add user with home and bash as shell
	groupadd -g ${PGID} ${USERNAME} && \
	useradd -d /home/${USERNAME} -s /bin/bash -u ${PUID} -g ${PGID} ${USERNAME} && \
	chown -R ${USERNAME} /home/${USERNAME} && \
	# Give user permissions for DBUS
	sed -i "/  <user>/c\  <user>${USERNAME}</user>" /usr/share/dbus-1/system.conf && \
	mkdir -p /var/run/dbus && \
	chown -R ${PUID}:${PGID} /var/run/dbus/ && \
	chmod -R 770 /var/run/dbus/ && \
	# Give user permissions on input
	mkdir -p /dev/uinput && \
		# TODO: check that volume does not break these
		# Otherwise add to init script
	chmod 0666 /dev/uinput && \
	# Create user config directories
	mkdir -p /home/${USERNAME}/.config/sunshine && \
	# Give user extra groups
	usermod -aG audio,games,messagebus ${USERNAME}

# Setup services to run & set them to run under our new user
# Using supervisord
# @see https://docs.docker.com/engine/containers/multi-service_container/#use-a-process-manager
# @see https://supervisord.org/introduction.html#platform-requirements
COPY ./config/supervisord/supervisord.conf /etc/supervisord/supervisord.conf
RUN find /plasma/runtime/services -type f -name "*.plasma.service" -exec sed -i "s/<USERNAME>/${USERNAME}/g" {} +

ENTRYPOINT ["/plasma/init.sh"]
