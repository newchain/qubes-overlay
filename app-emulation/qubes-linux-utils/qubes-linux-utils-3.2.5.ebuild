# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-utils.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils git-r3 python-single-r1 qubes

DESCRIPTION='Qubes utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-utils'

IUSE="balloon -debug python +udev"

qubes_keywords
LICENSE='GPL-2'

qubes_slot

CDEPEND="${CDEPEND}
	app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/xen-tools
	python? ( ${PYTHON_DEPS} )"

tag_date='20170924'
qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}"

HDEPEND="|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"

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

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user


	sed -i -e 's|/etc/udev/rules\.d|/lib/udev/rules.d|g' -- "${S}/udev/Makefile"

	for dir in qmemman qrexec-lib; do

		sed -i -e 's/\ -Werror//g' \
		       -e "2s/^CFLAGS\(\ \?+\?=\ \?.*\)$/CFLAGS\1 ${CFLAGS}/" -- "${S}/${dir}/Makefile"

	done

	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- "${S}/qrexec-lib/Makefile"

	! use balloon && sed -i -e '/qmemman/d' -- "${S}/Makefile"

	if ! use debug; then

		sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/qmemman/Makefile"
		sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/qrexec-lib/Makefile"

	fi

	! use python && sed -i -e '/core/d' -- "${S}/Makefile"

	! use udev && sed -i -e '/udev/d' -- "${S}/Makefile"
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="${D}" install

	[ -e "${D}/lib/udev" ] && fperms 0700 '/lib/udev'
	[ -e "${D}/lib/udev/rules.d" ] && fperms 0700 '/lib/udev/rules.d'
	[ -e "${D}/lib/udev/rules.d/99-qubes-block.rules" ] && fperms 0700 '/lib/udev/rules.d/99-qubes-block.rules'
	[ -e "${D}/lib/udev/rules.d/99-qubes-misc.rules" ] && fperms 0700 '/lib/udev/rules.d/99-qubes-misc.rules'
	[ -e "${D}/lib/udev/rules.d/99-qubes-usb.rules" ] && fperms 0700 '/lib/udev/rules.d/99-qubes-usb.rules'
	[ -e "${D}/usr/lib/qubes" ] && fperms 0711 '/usr/lib/qubes'
	[ -e "${D}/usr/lib/qubes/udev-block-add-change" ] && fperms 0700 '/usr/lib/qubes/udev-block-add-change'
	[ -e "${D}/usr/lib/qubes/udev-block-cleanup" ] && fperms 0700 '/usr/lib/qubes/udev-block-cleanup'
	[ -e "${D}/usr/lib/qubes/udev-block-remove" ] && fperms 0700 '/usr/lib/qubes/udev-block-remove'
	[ -e "${D}/usr/lib/qubes/udev-usb-add-change" ] && fperms 0700 '/usr/lib/qubes/udev-usb-add-change'
	[ -e "${D}/usr/lib/qubes/udev-usb-remove" ] && fperms 0700 '/usr/lib/qubes/udev-usb-remove'
}
