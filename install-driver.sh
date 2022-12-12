#!/bin/bash

# Purpose: Install Realtek out-of-kernel USB WiFi adapter drivers.
#
# Supports dkms and non-dkms installations.

# Copyright(c) 2022 Nick Morrow
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

SCRIPT_NAME="install-driver.sh"
SCRIPT_VERSION="20221208"
MODULE_NAME="8821cu"
DRV_VERSION="5.12.0.4"
# Some distros have a not yet mainlined, patched-in kernel driver that
# must be deactivated so as not to conflict with this driver. The
# filename may need to change when the new in-kernel driver is mainlined.
BLACKLIST_FILE="rtw88_8821cu.conf"

KVER="$(uname -r)"
KARCH="$(uname -m)"
KSRC="/lib/modules/${KVER}/build"
MODDESTDIR="/lib/modules/${KVER}/kernel/drivers/net/wireless/"

DRV_NAME="rtl${MODULE_NAME}"
DRV_DIR="$(pwd)"
OPTIONS_FILE="${MODULE_NAME}.conf"

# check to ensure sudo was used
if [[ $EUID -ne 0 ]]
then
	echo "You must run this script with superuser (root) privileges."
	echo "Try: \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# check to ensure gcc is installed
if ! command -v gcc >/dev/null 2>&1
then
	echo "A required package appears to not be installed."
	echo "Please install the following package: gcc"
	echo "Once the package is installed, please run \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# check to ensure make is installed
if ! command -v make >/dev/null 2>&1
then
	echo "A required package appears to not be installed."
	echo "Please install the following package: make"
	echo "Once the package is installed, please run \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# check to see if header files are installed
if [ ! -d "/lib/modules/$(uname -r)/build" ]; then
	echo "Your kernel headers aren't properly installed."
	echo "Please consult your distro documentation."
	echo "Once the header files are installed, please run \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# check to ensure iw is installed
if ! command -v iw >/dev/null 2>&1
then
	echo "A required package appears to not be installed."
	echo "Please install the following package: iw"
	echo "Once the package is installed, please run \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# check to ensure rfkill is installed
if ! command -v rfkill >/dev/null 2>&1
then
	echo "A required package appears to not be installed."
	echo "Please install the following package: rfkill"
	echo "Once the package is installed, please run \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# check to ensure nano is installed
if ! command -v nano >/dev/null 2>&1
then
	echo "A required package appears to not be installed."
	echo "Please install the following package: nano"
	echo "Once the package is installed, please run \"sudo ./${SCRIPT_NAME}\""
	exit 1
fi

# support for the NoPrompt option allows non-interactive use of this script
NO_PROMPT=0

# get the script options
while [ $# -gt 0 ]
do
	case $1 in
		NoPrompt)
			NO_PROMPT=1 ;;
		*h|*help|*)
			echo "Syntax $0 <NoPrompt>"
			echo "       NoPrompt - noninteractive mode"
			echo "       -h|--help - Show help"
			exit 1
			;;
	esac
	shift
done

# displays script name and version
echo "Running ${SCRIPT_NAME} version ${SCRIPT_VERSION}"

# check for and remove non-dkms installation
if [[ -f "${MODDESTDIR}${MODULE_NAME}.ko" ]]
then
	echo "Removing a non-dkms installation."
	rm -f ${MODDESTDIR}${MODULE_NAME}.ko
	/sbin/depmod -a ${KVER}
fi

# information that helps with bug reports

# display kernel version
echo "Linux Kernel=${KVER}"

# display architecture
echo "CPU Architecture=${KARCH}"

# display gcc version
gcc_ver=$(gcc --version | grep -i gcc)
echo "gcc --version="${gcc_ver}

# display ISO 3166-1 alpha-2 Country Code
a2_country_code=$(iw reg get | grep -i country)
echo "Country Code="${a2_country_code}
#if [[ $a2_country_code == *"00"* ]];
#then
#    echo "The Country Code is not properly set."
#    echo "File alpha-2_Country_Codes is located in the driver directory."
#    echo "Please read and follow the directions in the file."
#fi

# display secure mode status
# run if mokutil is installed
if command -v mokutil >/dev/null 2>&1
then
	mokutil --sb-state
fi

# blacklist the in-kernel module (driver) so that there is no conflict
echo "Installing ${BLACKLIST_FILE} to: /etc/modprobe.d"
cp -f ${BLACKLIST_FILE} /etc/modprobe.d

# sets module parameters (driver options)
echo "Installing ${OPTIONS_FILE} to: /etc/modprobe.d"
cp -f ${OPTIONS_FILE} /etc/modprobe.d

# determine if dkms is installed and run the appropriate routines
if ! command -v dkms >/dev/null 2>&1
then
	echo "The non-dkms installation routines are in use."

	make clean >/dev/null 2>&1

	make
	RESULT=$?

	if [[ "$RESULT" != "0" ]]
	then
		echo "An error occurred. Error = ${RESULT}"
		echo "Please report this error."
		echo "Please copy all screen output and paste it into the report."
		echo "You will need to run the following before reattempting installation."
		echo "$ sudo ./remove-driver.sh"
		exit $RESULT
	fi

# 	As shown in Makefile
# 	install:
#		install -p -m 644 $(MODULE_NAME).ko  $(MODDESTDIR)
#		/sbin/depmod -a ${KVER}
	make install
	RESULT=$?

	if [[ "$RESULT" = "0" ]]
	then
        make clean >/dev/null 2>&1
		echo "The driver was installed successfully."
	else
		echo "An error occurred. Error = ${RESULT}"
		echo "Please report this error."
		echo "Please copy all screen output and paste it into the report."
		echo "You will need to run the following before reattempting installation."
		echo "$ sudo ./remove-driver.sh"
		exit $RESULT
	fi
else
	echo "The dkms installation routines are in use."

# 	the dkms add command requires source in /usr/src/${DRV_NAME}-${DRV_VERSION}
	echo "Copying source files to: /usr/src/${DRV_NAME}-${DRV_VERSION}"
	cp -rf "${DRV_DIR}" /usr/src/${DRV_NAME}-${DRV_VERSION}
	
	dkms add -m ${DRV_NAME} -v ${DRV_VERSION}
	RESULT=$?

#	RESULT will be 3 if the DKMS tree already contains the same module/version
#	combo. You cannot add the same module/version combo more than once.
	if [[ "$RESULT" != "0" ]]
	then
		if [[ "$RESULT" = "3" ]]
		then
			echo "Run the following and then reattempt installation."
			echo "$ sudo ./remove-driver.sh"
			exit $RESULT 
		else
			echo "An error occurred. dkms add error = ${RESULT}"
			echo "Please report this error."
			echo "Please copy all screen output and paste it into the report."
			echo "Run the following before reattempting installation."
			echo "$ sudo ./remove-driver.sh"
			exit $RESULT
		fi
	else
		echo "The driver was added to dkms successfully."
	fi

	dkms build -m ${DRV_NAME} -v ${DRV_VERSION}
	RESULT=$?

	if [[ "$RESULT" != "0" ]]
	then
		echo "An error occurred. dkms build error = ${RESULT}"
		echo "Please report this error."
		echo "Please copy all screen output and paste it into the report."
		echo "Run the following before reattempting installation."
		echo "$ sudo ./remove-driver.sh"
		exit $RESULT
	else
		echo "The driver was built by dkms successfully."
	fi

	dkms install -m ${DRV_NAME} -v ${DRV_VERSION}
	RESULT=$?

	if [[ "$RESULT" != "0" ]]
	then
		echo "An error occurred. dkms install error = ${RESULT}"
		echo "Please report this error."
		echo "Please copy all screen output and paste it into the report."
		echo "Run the following before reattempting installation."
		echo "$ sudo ./remove-driver.sh"
		exit $RESULT
	else
		echo "The driver was installed by dkms successfully."
	fi
fi

# unblock wifi
if command -v rfkill >/dev/null 2>&1
then
	rfkill unblock wlan
else
	echo "Unable to run $ rfkill unblock wlan"	
fi

# if NoPrompt is not used, ask user some questions to complete installation
if [ $NO_PROMPT -ne 1 ]
then
	read -p "Do you want to edit the driver options file now? [y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		nano /etc/modprobe.d/${OPTIONS_FILE}
	fi

	read -p "Do you want to reboot now? (recommended) [y/N] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		reboot
	fi
fi

exit 0
