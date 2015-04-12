# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-utils.git'

PYTHON_COMPAT=( python2_7 )

inherit eutils git-2 python-r1 qubes

DESCRIPTION='Qubes utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-utils'

KEYWORDS=""
LICENSE='GPL-2'

qubes_slot

RDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/xen-tools"
DEPEND="app-crypt/gnupg
	>=app-emulation/qubes-secpack-20150603
	${DEPEND}
	${RDEPEND}"


src_prepare() {

	version_prefix='v'
	qubes_prepare

	epatch_user


	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- 'qrexec-lib/Makefile'

	sed -i 's|/etc/udev/rules\.d|/lib/udev/rules.d|g' -- 'udev/Makefile'

	for i in qmemman qrexec-lib; do {

		sed -i 's/\ -Werror//g' -- "${i}/Makefile"
	};
	done
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="${D}" install
}
