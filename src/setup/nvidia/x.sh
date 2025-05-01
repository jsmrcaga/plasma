#!/bin/bash

set -e

# Configure X for nvidia
# Code atttribution to Josh5 (https://github.com/josh5)
# @see https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/overlay/etc/cont-init.d/70-configure_xorg.sh#L32

function config_x_for_nvidia {
  DRIVER_MAJOR_VERSION=$(echo ${NVIDIA_DRIVER_VERSION:?} | awk -F '.' '{print $1}')
  # Small check in case driver does not support --no-multigpu flag
  if [[ $DRIVER_MAJOR_VERSION -lt 550 ]]; then
    EXTRA_X_NVIDIA_FLAGS="--no-multigpu"
  else
    EXTRA_X_NVIDIA_FLAGS=""
  fi

  DISPLAY_W="${DISPLAY_WIDTH:-1920}"
  DISPLAY_H="${DISPLAY_HEIGHT:-1080}"

  MODELINE=$(cvt -r "${DISPLAY_W}" "${DISPLAY_H}" "${DISPLAY_REFRESH:-60}" | sed -n 2p)
  MODE=$(echo $MODELINE | awk '{print $2}' | tr -d '"')

  # This assumes only 1 GPU connected
  # Otherwise add: --id="${selected_gpu}"
  # @see https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/overlay/etc/cont-init.d/70-configure_xorg.sh#L8
  nvidia_gpu_hex_id=$(nvidia-smi --format=csv --query-gpu=pci.bus_id 2> /dev/null | sed -n 2p)
  nvidia_gpu_id=${nvidia_gpu_hex_id:-"00000000:01:00.0"}
  # nvidia_gpu_hex_id="00000000:01:00.0"
  IFS=":." ARR_ID=(${nvidia_gpu_id})
  unset IFS

  bus_id=PCI:$((16#${ARR_ID[1]})):$((16#${ARR_ID[2]})):$((16#${ARR_ID[3]}))

  # --use-display-device=None
  # @see https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/overlay/etc/cont-init.d/70-configure_xorg.sh#L41C24-L41C49
  # @see https://developer.nvidia.com/docs/drive/drive-os/archives/6.0.4/linux/sdk/common/topics/window_system_stub/Togetoptionsformodifyingxorg.conf55.html
  nvidia-xconfig \
    --virtual="${DISPLAY_W}x${DISPLAY_H}" \
    --depth="${DISPLAY_DEPTH:-24}" \
    --mode="${MODE}" \
    --allow-empty-initial-configuration \
    --no-probe-all-gpus \
    --busid="${bus_id:?}" \
    --no-sli \
    --no-base-mosaic \
    --only-one-x-screen \
    --use-display-device=None \
    $EXTRA_X_NVIDIA_FLAGS

  # Add extra configuration
  # All credit goes to Josh5
  # @see https://github.com/Steam-Headless/docker-steam-headless/blob/14c770bce61db99c56592760c73c2ba454dab648/overlay/etc/cont-init.d/70-configure_xorg.sh#L47

  sed -i '/Driver\s\+"nvidia"/a\
    Option "AllowExternalGpus" "True"\
    Option "PrimaryGPU" "yes"\
    Option "AllowEmptyInitialConfiguration"\
    Option "ModeValidation" "NoMaxPClkCheck, NoEdidMaxPClkCheck, NoMaxSizeCheck, NoHorizSyncCheck, NoVertRefreshCheck, NoVirtualSizeCheck, NoTotalSizeCheck, NoDualLinkDVICheck, NoDisplayPortBandwidthCheck, AllowNon3DVisionModes, AllowNonHDMI3DModes, AllowNonEdidModes, NoEdidHDMI2Check, AllowDpInterlaced"' /etc/X11/xorg.conf

  sed -i '/Section\s\+"Monitor"/a\    '"${MODELINE}" /etc/X11/xorg.conf
  echo -e 'Section "ServerFlags"
  Option "AutoAddGPU" "false"
EndSection' | tee -a /etc/X11/xorg.conf > /dev/null

  # Explanation:
  # Allow SteamHeadless to run with an eGPU
    # Option "AllowExternalGpus" "True"
  # Configure primary GPU
    # Option "PrimaryGPU" "yes"
  # Force X server to start even if no display devices are connected
    # Option "AllowEmptyInitialConfiguration"
  # Disable some mode validation checks
    # Option "ModeValidation" "NoMaxPClkCheck, ...
  # Configure the default modeline
    # ${MODELINE}
  # Prevent interference between GPUs
    # Option "AutoAddGPU" "false"
}

if [ -f /plasma/init.d/nvidia-x.done ]; then
  echo "[INFO] Nvidia already initialized"
  exit 0
fi

config_x_for_nvidia

# Mark script as done
touch /plasma/init.d/nvidia-x.done
