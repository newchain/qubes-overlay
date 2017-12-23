# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-utils.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils git-r3 python-single-r1 qubes

DESCRIPTION='Qubes utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-utils'

IUSE="balloon python"

[ "${PV%%[_-]*}" != '9999' ] && [ "${PV%%.*}" != '4' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/xen-tools"

qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}"

RDEPEND="${CDEPEND}"


src_unpack() {

	version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user


	sed -i 's|/etc/udev/rules\.d|/lib/udev/rules.d|g' -- 'udev/Makefile'

	for dir in qmemman qrexec-lib
	do

		sed -i 's/\ -Werror//g' -- "${dir}/Makefile"

	done

	if ! use balloon
	then

	  sed -i '/qmemman/d' -- 'Makefile'

	fi

	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- 'qrexec-lib/Makefile'

}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="${D}" install
}
