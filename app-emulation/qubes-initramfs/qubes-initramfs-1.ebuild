# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils

DESCRIPTION='initramfs for Gentoo PV domUs on Qubes.'

IUSE="genkernel"
KEYWORDS="~amd64"
LICENSE='GPL-2'
SLOT='0'

RDEPEND="app-arch/cpio
	app-arch/gzip
	sys-apps/findutils

	!genkernel? (
		sys-apps/busybox[static]
		sys-fs/lvm2[static]
	)"


pkg_setup() {

	mkdir -p -- "${S}"
}

src_install() {

	exeinto '/usr/bin'
	doexe "${FILESDIR}/qubes-initramfs"

	dodir '/usr/share/qubes'
	insinto '/usr/share/qubes'
	doins "${FILESDIR}/init"
}
