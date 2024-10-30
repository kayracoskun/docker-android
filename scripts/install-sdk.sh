#!/bin/bash

set -e

# If the INSTALL_ANDROID_SDK flag is set to 1,
# proceed with downloading and installing the Android SDK,
# platform tools, and the specified Automotive emulator image.
if [ "$INSTALL_ANDROID_SDK" == "1" ]; then
  echo "Installing the Android SDK, platform tools, and emulator ..."
  
  # Download and install the Android SDK command-line tools
  wget https://dl.google.com/android/repository/commandlinetools-linux-${CMD_LINE_VERSION}.zip -P /tmp && \
  mkdir -p $ANDROID_SDK_ROOT/cmdline-tools/ && \
  unzip -d $ANDROID_SDK_ROOT/cmdline-tools/ /tmp/commandlinetools-linux-${CMD_LINE_VERSION}.zip && \
  mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools/ $ANDROID_SDK_ROOT/cmdline-tools/tools/ && \
  rm /tmp/commandlinetools-linux-${CMD_LINE_VERSION}.zip
  
  # Accept SDK licenses
  yes | sdkmanager --licenses

  # Refresh SDK repository list
  echo "Updating SDK repository list ..."
  yes | sdkmanager --update
  
  # Attempt to install the Automotive OS system image after updating
  echo "Installing the Android Automotive OS system image ..."
  sdkmanager --install "$PACKAGE_PATH" || { 
    echo "Failed to install $PACKAGE_PATH. Retrying after update..."; 
    sdkmanager --update && sdkmanager --install "$PACKAGE_PATH"; 
  }

  # Install additional SDK components required for the emulator
  sdkmanager --install "$ANDROID_PLATFORM_VERSION" platform-tools emulator
fi
