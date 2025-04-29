# In CI this should be the "last"
# version we built
ARG PLASMA_VERSION=latest
FROM plasma:${PLASMA_VERSION}

ARG NVIDIA_DRIVER_CAPABILITIES="all"
ARG NVIDIA_VISIBLE_DEVICES="all"
ARG NVIDIA_DRIVER_VERSION="570.133.07"

# Configure fake display
COPY ./config/video/xorg/xorg.conf /etc/X11/xorg.conf

# Automatically add graphic cards
# for Container toolkit env variables
ENV \
	NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES} \
	NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES}

# Nvidia drivers section
# * Blacklist nouveau
# * Install linux headers
# * Install nvidia 32-bit libs and nvidia driver
RUN usermod -aG messagebus lizard
COPY ./src/setup/nvidia/install_nvidia_drivers.sh /etc/plasma-setup/install_nvidia_drivers.sh
RUN bash /etc/plasma-setup/install_nvidia_drivers.sh

ENTRYPOINT ["/plasma/init.sh"]
