# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION='initramfs for Gentoo PV domUs on Qubes.'

IUSE="genkernel"
KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND:-}
	${RDEPEND:-}
	|| (
		app-arch/cpio
		sys-apps/busybox
	)
	|| (
		app-arch/gzip
		sys-apps/busybox
	)
	sys-apps/file
	|| (
		sys-apps/findutils
		sys-apps/busybox
	)
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

	insinto '/usr/share/qubes'
	doins "${FILESDIR}/init"
}
