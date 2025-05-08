#!/bin/bash

# Start X server
# Credit for all flags to Josh5
/usr/bin/Xorg \
    -ac \
    -noreset \
    -novtswitch \
    -sharevts \
    +extension RANDR \
    +extension RENDER \
    +extension GLX \
    +extension XVideo \
    +extension DOUBLE-BUFFER \
    +extension SECURITY \
    +extension DAMAGE \
    +extension X-Resource \
    -extension XINERAMA -xinerama \
    +extension Composite +extension COMPOSITE \
    -dpms \
    -s off \
    -nolisten tcp \
    -iglx \
    -verbose \
    vt7 "${DISPLAY:?}"
