# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit user

DESCRIPTION='Base files for torsocksunix'
HOMEPAGE='https://github.com/newchain/torsocksunix'

IUSE="selinux"

KEYWORDS="amd64 x86"
LICENSE='AGPL-3'
SLOT='0'

HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND:-}
	${RDEPEND:-}
	app-emulation/qubes-core-agent-linux
	net-misc/socat
	|| (
		sys-apps/coreutils
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
	virtual/tmpfiles
	selinux? ( sec-policy/selinux-socat_qrexec )"


pkg_setup() {

	mkdir -p -- "${S}"

	enewgroup qrexec-client
}

src_install() {

	diropts -g qubes -m 0710
	dodir '/usr/lib/qubes'

	diropts -m 0700
	dodir '/usr/lib/qubes/init'
	dodir '/usr/lib/tmpfiles.d'

	insopts -m 0600

	insinto '/usr/lib/qubes/init'
	doins "${FILESDIR}/torsocksunix"

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/socat_qrexec.conf"
}
