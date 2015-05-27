# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-vchan-xen.git'

inherit eutils git-2 qubes

DESCRIPTION='Qubes I/O libraries'
HOMEPAGE='https://github.com/QubesOS/qubes-core-vchan-xen'

KEYWORDS=""
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

	emake all;
}

src_install() {

	if ! [ ${SLOT} == 2 ]; then {

		# qubes-linux-utils for R3 expects vchan-, not vchan-xen
		#
		ln -s -- '/usr/lib/pkgconfig/vchan-xen.pc' 'vchan-.pc'

		insinto '/usr/lib/pkgconfig'
		doins  'vchan-.pc'
	};
	fi

		emake DESTDIR="${D}" install

		insinto '/usr/share/qubes'
		doins "${FILESDIR}/xenstore-do-not-use-broken-kernel-interface.patch"
}

pkg_postinst() {

	echo
	ewarn "You must apply xenstore-do-not-use-broken-kernel-interface.patch
	ewarn "to app-emulation/xen-tools.
	echo
}
