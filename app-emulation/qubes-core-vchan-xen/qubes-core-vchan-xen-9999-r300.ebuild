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

	sed -i "s:/usr/lib/\(libu2mfn\.so\|libvchan-xen\.so\):/usr/$(get_libdir)/\1:" -- 'Makefile'

	sed -i 's/\ -Werror//' -- 'vchan/Makefile.linux'

	sed -i "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- 'u2mfn/Makefile'
	sed -i "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- 'vchan/Makefile.linux'
}

src_compile() {

	emake LIBDIR="/usr/$(get_libdir)" all
}

src_install() {

	emake DESTDIR="${D}" LIBDIR="/usr/$(get_libdir)" install

	insinto '/etc/portage/patches/app-emulation/xen-tools'
	doins "${FILESDIR}/xenstore-do-not-use-broken-kernel-interface_4.6.patch"

	insinto '/etc/portage/patches/app-emulation/xen-tools-4.5'
	doins "${FILESDIR}/xenstore-do-not-use-broken-kernel-interface_4.5.patch"

	insinto '/usr/share/qubes/patches'
	doins "${FILESDIR}/xenstore-do-not-use-broken-kernel-interface_4.5.patch"
	doins "${FILESDIR}/xenstore-do-not-use-broken-kernel-interface_4.6.patch"
}

pkg_postinst() {

	echo
	ewarn "You must apply xenstore-do-not-use-broken-kernel-interface_4.6.patch"
	ewarn "to app-emulation/xen-tools."
	echo
}
