# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-utils.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils git-r3 python-single-r1 qubes

DESCRIPTION='Qubes utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-utils'

IUSE="balloon -debug python +udev"

[ "${PV%%[_-]*}" != '9999' ] && [ "${PV%%.*}" != '4' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/xen-tools"

tag_date='20160208'
qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}"

RDEPEND="${CDEPEND}
	python? ( || (
	  dev-python/cairocffi
	  dev-python/pycairo
	) )
	udev? ( virtual/udev )"


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
	  sed -i "2s/^CFLAGS\(\ \?+\?=\ \?.*\)$/CFLAGS\1 ${CFLAGS}/" -- "${dir}/Makefile"

	done

	if ! use debug
	then

	  sed -i 's/\(CFLAGS.*\)-g\ /\1/' -- 'qmemman/Makefile'
	  sed -i 's/\(CFLAGS.*\)-g\ /\1/' -- 'qrexec-lib/Makefile'

	fi

	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- 'qrexec-lib/Makefile'

	if ! use balloon
	then

	  sed -i '/qmemman/d' -- 'Makefile'

	fi

	if ! use python
	then

	  sed -i '/core/d' -- 'Makefile'

	fi

	if ! use udev
	then

	  sed -i '/udev/d' -- 'Makefile'

	fi
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="${D}" install
}
