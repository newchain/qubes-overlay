# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-vchan-xen.git'

inherit eutils git-2 qubes

DESCRIPTION='Qubes I/O libraries'
HOMEPAGE='https://github.com/QubesOS/qubes-core-vchan-xen'

KEYWORDS="~amd64"
LICENSE='GPL-2'

qubes_slot

RDEPEND="app-emulation/xen-tools"
DEPEND="app-crypt/gnupg
	${DEPEND}
	${RDEPEND}"


src_prepare() {

	readonly version_prefix='v'
	qubes_prepare

	sed -i -- 's/\ -Werror//g' 'vchan/Makefile.linux'

	epatch_user
}

src_compile() {

	if [ ${SLOT} == 2 ]; then {

		emake all;

	}; else {

		cd "${S}/u2mfn"

		emake DESTDIR="${D}" all

		cd "${S}/vchan"

		emake DESTDIR="${D}" -f 'Makefile.linux' all
	};
	fi
}

src_install() {

	if [ ${SLOT} == 2 ]; then {

		emake DESTDIR="${D}" install

	}; else {

		cd "${S}/u2mfn"

		dolib 'libu2mfn.so'

		insinto '/usr/include'
		doins 'u2mfn-kernel.h'
		doins 'u2mfnlib.h'

		cd "${S}/vchan"

		dolib 'libvchan-xen.so'

		insinto '/usr/include'
		doins 'libvchan.h'

		insinto '/usr/lib/pkgconfig'
		newins 'vchan-xen.pc' 'vchan-.pc'
	};
	fi
}
