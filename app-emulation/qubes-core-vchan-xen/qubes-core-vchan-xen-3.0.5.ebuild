# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-vchan-xen.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils git-r3 qubes

DESCRIPTION='Qubes I/O libraries'
HOMEPAGE='https://github.com/QubesOS/qubes-core-vchan-xen'

[ "${PV%%[_-]*}" != '9999' ] && [ "${PV%%.*}" != '4' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/xen-tools"

tag_date='20150503'
qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}"

RDEPEND="${CDEPEND}"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user

	sed -ie "s:/usr/lib/\(libu2mfn\.so\|libvchan-xen\.so\):/usr/$(get_libdir)/\1:" -- 'Makefile'

	sed -ie 's/\ -Werror//' -- 'vchan/Makefile.linux'

	sed -ie "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- 'u2mfn/Makefile'
	sed -ie "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- 'vchan/Makefile.linux'
}

src_compile() {

	emake LIBDIR="/usr/$(get_libdir)" all
}

src_install() {

	emake DESTDIR="${D}" LIBDIR="/usr/$(get_libdir)" install
}
