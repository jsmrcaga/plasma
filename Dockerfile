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
	apt-get install --no-install-recommends -y \
		# General
		wget \
		nano \
		locales \
		# Desktop interface
		kwin-x11 \
		# Some programs require a terminal emulator
		xterm \
		# Supervisor handles our user processes at startup
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
		# Allows testing graphics
		xfishtank \
		glmark2 \
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
RUN apt-get update && \
	apt-get install -y --no-install-recommends /plasma/sunshine.deb && \
	apt-get clean autoclean -y && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* /var/tmp/* && \
	rm /plasma/sunshine.deb

# Copy sunshine assets
COPY ./src/setup/sunshine/assets/* /usr/share/sunshine

# User/permissions config for X. Needed for all GPU types
COPY ./config/video/xorg/Xwrapper.conf /etc/X11/Xwrapper.config

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
	mkdir -p /home/default && \
	mkdir -p /home/default/.config/sunshine && \
	mkdir -p /home/default/.config/pulse && \
	# Add user with home and bash as shell
	groupadd -g ${PGID} ${USERNAME} && \
	useradd -m -d /home/${USERNAME} -s /bin/bash -u ${PUID} -g ${PGID} ${USERNAME} && \
	# Give user permissions for DBUS
	sed -i "/  <user>/c\  <user>${USERNAME}</user>" /usr/share/dbus-1/system.conf && \
	mkdir -p /var/run/dbus && \
	chown -R ${PUID}:${PGID} /var/run/dbus/ && \
	chmod -R 0770 /var/run/dbus/ && \
	# Give user permissions on input
	touch /dev/uinput && \
	chmod 0666 /dev/uinput && \
	# Give permissions on pulseaudio
	mkdir -p /tmp/pulse && \
	chown -R ${PUID}:${PGID} /tmp/pulse && \
	chmod -R 0770 /tmp/pulse && \
	# Give user extra groups (render is particularly useful for AMD Cloud)
	usermod -aG audio,games,messagebus,video,render,input,tty ${USERNAME}

# Setup services to run & set them to run under our new user
# Using supervisord
# @see https://docs.docker.com/engine/containers/multi-service_container/#use-a-process-manager
# @see https://supervisord.org/introduction.html#platform-requirements
COPY ./config/supervisord/supervisord.conf /etc/supervisor/supervisord.conf

# Will be used by steam and sunshine
ENV \
	HOME=/home/default \
	USER=${USERNAME}

# Configure Sunshine if necessary
ARG SUNSHINE_USERNAME
ARG SUNSHINE_PASSWORD

# Copy to /home/default so that the image can contain everything once built
RUN HOME=/home/default /plasma/setup/sunshine/sunshine-creds.sh $SUNSHINE_USERNAME $SUNSHINE_PASSWORD

COPY ./config/sunshine /home/default/.config/sunshine

# Install Steam
#   * Order of operations is extramely important here
#   * non-free-firmware is a small optimization for the nvidia image
RUN \
	echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
	echo "deb http://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list.d/backports.list && \
	dpkg --add-architecture i386 && \
	apt-get update && \

	# Install GL, Mesa & Vulkan drivers from backports
	apt-get install -y --no-install-recommends -t bookworm-backports \
		# this includes libgbm.so.1 32bit, otherwise steam dies
		libgbm-dev:i386 \
		libegl1:amd64 \
		libegl1:i386 \
		libglx-mesa0:i386 \
		libglx-mesa0:amd64 \
		libgl1-mesa-dri:amd64 \
		libgl1-mesa-dri:i386 \
		mesa-vulkan-drivers:amd64 \
		mesa-vulkan-drivers:i386 \
		libdrm-amdgpu1:amd64 \
		libdrm-amdgpu1:i386 && \

	# Install rest from normal repo
	apt-get install -y --no-install-recommends \
		gamescope \
		# Some necessities for Steam
		xfonts-base \
		msttcorefonts \
		fonts-liberation \
		# This is needed for some operations Steam does (throws an error otherwise)
		xdg-user-dirs \
		# Extra steam dependencies
		# 	pcituils installs lspci for steam
		pciutils \
		libcurl4-openssl-dev:i386 \
		libcurl4-openssl-dev:amd64 \
		libc6:amd64 \
		libc6:i386 \
		libgbm1:amd64 \
		libgbm1:i386 \
		# This includes libGL.so.1
		libgl1:i386 \
		libgl1:amd64 \
		steam-libs-amd64:amd64 \
		steam-libs-i386:i386 \
		# Install steam
		steam-installer && \
	apt-get clean autoclean -y && \
	apt-get autoremove -y && \
	rm -rf /var/lib/apt/lists/* /var/tmp/*

# Re-set home to the actual user
ENV HOME=/home/${USERNAME}

RUN \
	# Make sure the user has permissions on all their home things
	# Since root will have created a ton of stuff in the meantime
	chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

ENTRYPOINT ["/plasma/init.sh"]
