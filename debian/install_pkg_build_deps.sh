#!/bin/bash

# EXEMPT_POSTINST is used to bypass the 'set -e' command which makes the script exit immediately if a command exits with a non-zero status.
# This is useful when the script is expected to fail in some cases.
[ -z "$EXEMPT_POSTINST" ] && set -e

# Enable debugging if DEBUG is defined
[ -n "$DEBUG" ] && set -x

echo "Installing Debian package build dependencies"

apt-get update -qq

apt-get install -y \
  python3 python3-dev python3-pip python3-venv python3-all \
  dh-python debhelper devscripts dput software-properties-common \
  python3-distutils python3-setuptools python3-wheel python3-stdeb \
  dkms bc debmake build-essential linux-headers-generic
# dh-dkms doesn't seem to exist in Ubuntu?