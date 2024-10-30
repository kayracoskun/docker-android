#!/bin/bash

set -e

# Source the emulator monitoring script
source ./emulator-monitoring.sh

# Define the emulator console and ADB ports
EMULATOR_CONSOLE_PORT=5554
ADB_PORT=5555
OPT_MEMORY=${MEMORY:-8192}
OPT_CORES=${CORES:-4}
OPT_SKIP_AUTH=${SKIP_AUTH:-true}
AUTH_FLAG=

# Screen resolution for the emulator
SCREEN_RESOLUTION="1280x800"

# Start the ADB server to listen on all interfaces
echo "Starting the ADB server ..."
adb -a -P 5037 server nodaemon &

# Detect IP and forward ADB ports from the container's network interface to localhost
LOCAL_IP=$(ip addr list eth0 | grep "inet " | cut -d' ' -f6 | cut -d/ -f1)
socat tcp-listen:"$EMULATOR_CONSOLE_PORT",bind="$LOCAL_IP",fork tcp:127.0.0.1:"$EMULATOR_CONSOLE_PORT" &
socat tcp-listen:"$ADB_PORT",bind="$LOCAL_IP",fork tcp:127.0.0.1:"$ADB_PORT" &

export USER=root

# Check if an Automotive Virtual Device (AVD) already exists, or create one if it doesn’t
TEST_AVD=$(avdmanager list avd | grep -c "android.avd" || true)
if [ "$TEST_AVD" == "1" ]; then
  echo "Using the existing Automotive Virtual Emulator ..."
else
  echo "Creating the Automotive Virtual Emulator ..."
  echo "Using package '$PACKAGE_PATH', ABI '$ABI', and device '$DEVICE_ID' for creating the emulator"
  echo no | avdmanager create avd \
    --force \
    --name automotive_avd \
    --abi "$ABI" \
    --package "$PACKAGE_PATH" \
    --device "$DEVICE_ID"
fi

# Configure ADB authentication skipping if specified
if [ "$OPT_SKIP_AUTH" == "true" ]; then
  AUTH_FLAG="-skip-adb-auth"
fi

# GPU acceleration setup
if [ "$GPU_ACCELERATED" == "true" ]; then
  export DISPLAY=":0.0"
  export GPU_MODE="host"
  Xvfb "$DISPLAY" -screen 0 1920x1080x16 -nolisten tcp &
else
  export GPU_MODE="swiftshader_indirect"
fi

# Start boot monitoring asynchronously
wait_for_boot &

# Start the emulator with specified screen resolution, no audio, no GUI, and no snapshots
echo "Starting the Automotive OS emulator ..."
echo "OPTIONS:"
echo "SKIP ADB AUTH - $OPT_SKIP_AUTH"
echo "GPU           - $GPU_MODE"
echo "MEMORY        - $OPT_MEMORY"
echo "CORES         - $OPT_CORES"
echo "RESOLUTION    - $SCREEN_RESOLUTION"
emulator \
  -avd automotive_avd \
  -gpu "$GPU_MODE" \
  -memory $OPT_MEMORY \
  -no-boot-anim \
  -cores $OPT_CORES \
  -ranchu \
  $AUTH_FLAG \
  -no-window \
  -no-snapshot \
  -skin "$SCREEN_RESOLUTION" || update_state "ANDROID_STOPPED"

# -qemu and additional options can be added here if needed
