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

RUN apt-get update && \
	# --no-install-recommends breaks the dbus/system.conf file
	apt-get install -y \
		# General
		locales \
		supervisor \
		# Sunshine
		va-driver-all \
		# Audio
		pulseaudio \
		alsa-utils \
		libasound2 \
		libasound2-plugins \
		# X stuff
		x11-xserver-utils \
		xserver-xorg-core \
		# X input
		dbus-x11 \
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
	apt-get clean autoclean -y && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* /var/tmp/*

COPY --from=lizardbyte/sunshine:v2025.426.10137-debian-bookworm /sunshine.deb /plasma/sunshine.deb

# @see https://github.com/LizardByte/Sunshine/blob/3de3c299b23f64909bd6b3e42626ec818b0221d6/docker/debian-bookworm.dockerfile#L70
RUN apt-get install -y --no-install-recommends /plasma/sunshine.deb && \
	apt-get clean autoclean -y && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* /var/tmp/* \
	rm /plasma/sunshine.deb

# User/permissions config for X. Needed for all GPU types
COPY ./config/video/xorg/Xwrapper.conf /etc/X11/Xwrapper.config

# Configure display for AMD/Intel
# Full credit to Josh5
# @see https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/overlay/templates/xorg/xorg.dummy.conf
COPY ./config/video/xorg/xorg.conf /etc/X11/xorg.conf

# Configure audio
COPY ./config/audio/pulse/* /etc/pulse

# Configure input rules
COPY ./config/input/xorg/10-evdev.conf /etc/X11/xorg.conf.d/10-evdev.conf
COPY ./config/input/udev/99-sunshine.rules /etc/udev/rules.d/99-sunshine.rules

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
	# Create home and .config/sunshine too before chowning
	mkdir -p /home/${USERNAME} && \
	mkdir -p /home/${USERNAME}/.config/sunshine && \
	mkdir -p /home/${USERNAME}/.config/pulse && \
	# Add user with home and bash as shell
	groupadd -g ${PGID} ${USERNAME} && \
	useradd -m -d /home/${USERNAME} -s /bin/bash -u ${PUID} -g ${PGID} ${USERNAME} && \
	# Make sure the user has permissions on all their home things
	chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} && \
	# Give user permissions for DBUS
	sed -i "/  <user>/c\  <user>${USERNAME}</user>" /usr/share/dbus-1/system.conf && \
	mkdir -p /var/run/dbus && \
	chown -R ${PUID}:${PGID} /var/run/dbus/ && \
	chmod -R 770 /var/run/dbus/ && \
	# Give user permissions on input
	mkdir -p /dev/uinput && \
	chmod 0666 /dev/uinput && \
	# Give permissions on pulseaudio
	mkdir -p /tmp/pulse && \
	chmod -R 0666 /tmp/pulse && \
	# Give user extra groups
	usermod -aG audio,games,messagebus,video,input ${USERNAME}

# Setup services to run & set them to run under our new user
# Using supervisord
# @see https://docs.docker.com/engine/containers/multi-service_container/#use-a-process-manager
# @see https://supervisord.org/introduction.html#platform-requirements
COPY ./config/supervisord/supervisord.conf /etc/supervisor/supervisord.conf

# Will be used by steam and sunshine
ENV \
	HOME=/home/${USERNAME} \
	USER=${USERNAME}

# Configure Sunshine if necessary
ARG SUNSHINE_USERNAME
ARG SUNSHINE_PASSWORD
RUN \
	mkdir -p /home/${USERNAME}/.config/sunshine && \
	HOME=/home/${USERNAME} /plasma/setup/sunshine/sunshine-creds.sh $SUNSHINE_USERNAME $SUNSHINE_PASSWORD

COPY ./config/sunshine /home/${USERNAME}/.config/sunshine

# Install Steam
#   * Order of operations is extramely important here
#   * non-free-firmware is a small optimization for the nvidia image
RUN echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
	dpkg --add-architecture i386 && \
	apt-get update && \
	apt-get install -y --no-install-recommends \
		# @see https://developer.valvesoftware.com/wiki/Command_line_options#Steam
		steam-installer \
		gamescope \
		mesa-vulkan-drivers \
		libglx-mesa0:i386 \
		# this includes libgbm.so.1 32bit, otherwise steam dies
		libgbm-dev:i386 \
		# This is needed for some operations Steam does (throws an error otherwise)
		xdg-user-dirs \
		mesa-vulkan-drivers:i386 \
		libgl1-mesa-dri:i386 && \
	apt-get clean autoclean -y && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* /var/tmp/* && \
	# Make sure we have a steam binary ready to use
	ln -sf /usr/games/steam /usr/bin/steam

RUN \
	# Make sure the user has permissions on all their home things
	# Since root will have created a ton of stuff in the meantime
	chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

ENTRYPOINT ["/plasma/init.sh"]
