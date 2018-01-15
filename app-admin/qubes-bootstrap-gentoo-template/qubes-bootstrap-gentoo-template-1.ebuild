# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION='(WIP) Gentoo template bootstrapper'
HOMEPAGE='https://github.com/newchain/qubes-overlay'

IUSE=""
KEYWORDS=""
LICENSE='AGPL-3'
SLOT='0'

DEPEND="${CDEPEND:-}
	${DEPEND:-}"

HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND:-}
	${RDEPEND:-}
	|| (
		app-arch/tar
		sys-apps/busybox
	)
	app-crypt/gnupg
	app-crypt/gentoo-keys
	app-crypt/qubes-keys
	sys-apps/attr
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/diffutils
		sys-apps/busybox
	)
	|| (
		sys-apps/grep
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)
	|| (
		sys-apps/util-linux
		sys-apps/busybox
	)
	|| (
		sys-fs/e2fsprogs
		sys-apps/busybox
	)"


pkg_setup() {

	mkdir -p "${S}"
}

src_install() {

	diropts -g qubes -m 0710
	dodir '/usr/lib/qubes'

	exeopts -g qubes -m 0750
	exeinto '/usr/lib/qubes'
	doexe "${FILESDIR}/${PN#qubes-}.sh"
}
