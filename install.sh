#!/bin/bash

set -e

ARCH_INSTALL_SCRIPT="$(pwd)/scripts/arch/install.sh"
UBUNTU_INSTALL_SCRIPT="$(pwd)/scripts/ubuntu/install.sh"

detect_distro() {
  echo "Detecting Linux distribution..."
  echo "-------------------------------"
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    DISTRO_FAMILY=$ID_LIKE
    echo "Distribution ID     : $DISTRO"
    echo "Distribution Family : $ID_LIKE"

    if [[ "$DISTRO_FAMILY" == *"arch"* || "$DISTRO" == "arch" ]]; then
      bash "$ARCH_INSTALL_SCRIPT"
    elif [[ "$DISTRO_FAMILY" == *"debian"* || "$DISTRO_FAMILY" == *"ubuntu"* || "$DISTRO" == "ubuntu" ]]; then
      bash "$UBUNTU_INSTALL_SCRIPT"
    else
      echo "Unsupported Linux distribution: $DISTRO"
      exit 1
    fi
  fi
else
  echo "Cannot detect Linux distribution. /etc/os-release not found."
  exit 1
  fi
}

detect_distro
