# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-utils.git'

PYTHON_COMPAT=( python2_7 )

inherit eutils git-2 python-r1 qubes

DESCRIPTION='Qubes utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-utils'

KEYWORDS="~amd64"
LICENSE='GPL-2'

qubes_slot

RDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/xen-tools"
DEPEND="app-crypt/gnupg
	${DEPEND}
	${RDEPEND}"


src_prepare() {

	version_prefix='v'
	qubes_prepare

	sed -i -- 's|/etc/udev/rules\.d|/lib/udev/rules.d|g' 'udev/Makefile'

	for i in qmemman qrexec-lib; do {

		sed -i -- 's/\ -Werror//g' "${i}/Makefile"
	};
	done

	epatch_user
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="${D}" install
}
