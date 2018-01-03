# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-vchan-xen.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils git-r3 qubes

DESCRIPTION='Qubes I/O libraries'
HOMEPAGE='https://github.com/QubesOS/qubes-core-vchan-xen'

IUSE="-debug"
qubes_keywords
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/xen-tools"

tag_date='20150503'
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
	app-emulation/qubes-xen-tools-patches"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user

	sed -i -e "s:/usr/lib/\(libu2mfn\.so\|libvchan-xen\.so\):/usr/$(get_libdir)/\1:" -- "${S}/Makefile"

	sed -i -e 's/\ -Werror//' -- "${S}/vchan/Makefile.linux"

	sed -i -e "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- "${S}/u2mfn/Makefile"
	sed -i -e "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- "${S}/vchan/Makefile.linux"

	if ! use debug; then

		sed -i -e 's/-g\ //' -- "${S}/u2mfn/Makefile"
		sed -i -e 's/-g\ //' -- "${S}/vchan/Makefile.linux"

	fi
}

src_compile() {

	emake LIBDIR="/usr/$(get_libdir)" all
}

src_install() {

	emake DESTDIR="${D}" LIBDIR="/usr/$(get_libdir)" install
}
