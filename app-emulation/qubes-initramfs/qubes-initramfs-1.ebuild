# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils

DESCRIPTION='initramfs for Gentoo PV domUs on Qubes.'

IUSE="genkernel"
KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

RDEPEND="app-arch/cpio
	app-arch/gzip
	sys-apps/findutils

	!genkernel? (
		sys-apps/busybox[static]
		sys-fs/lvm2[static]
	)"


src_prepare() {

	eapply_user
}

pkg_setup() {

	mkdir -p -- "${S}"
}

src_install() {

	exeinto '/usr/bin'
	doexe "${FILESDIR}/qubes-initramfs"

	insinto '/usr/share/qubes'
	doins "${FILESDIR}/init"
}
