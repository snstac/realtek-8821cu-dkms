# SPDX-License-Identifier: GPL-2.0-only
################################################################################
#
# 8821cu is the Linux device driver released for Realtek 5 Gigabit Ethernet
# controllers with PCI-Express interface.
#
# Copyright(c) 2024 Realtek Semiconductor Corp. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, see <http://www.gnu.org/licenses/>.
#
# Author:
# Realtek NIC software team <nicfae@realtek.com>
# No. 2, Innovation Road II, Hsinchu Science Park, Hsinchu 300, Taiwan
#
################################################################################

################################################################################
#  This product is covered by one or more of the following patents:
#  US6,570,884, US6,115,776, and US6,327,625.
################################################################################

# To pass the dkms.conf parameters to the Makefile,
# add KVER and BASEDIR to the Make command line
KFLAG := 2$(shell "$KVER" | sed -ne 's/^2\.[4]\..*/4/p')x
BSRC ?= /lib/modules/$(shell uname -r)
KVERSION := $(shell uname -r)

all: clean modules install

modules:
ifeq ($(KFLAG),24x)
	$(MAKE) -C src/ KVER=$(KVERSION) BASEDIR=$(BSRC) -f Makefile_linux24x modules
else
	$(MAKE) -C src/ KVER=$(KVERSION) BASEDIR=$(BSRC) modules
endif

clean:
ifeq ($(KFLAG),24x)
	$(MAKE) -C src/ KVER=$(KVERSION) BASEDIR=$(BSRC) -f Makefile_linux24x clean
else
	$(MAKE) -C src/ KVER=$(KVERSION) BASEDIR=$(BSRC) clean
endif

install: modules
ifeq ($(KFLAG),24x)
	$(MAKE) -C src/ KVER=$(KVERSION) BASEDIR=$(BSRC) -f Makefile_linux24x install
else
	$(MAKE) -C src/ KVER=$(KVERSION) BASEDIR=$(BSRC) install
endif

package: modules
	dpkg-buildpackage -b -rfakeroot -us -uc
