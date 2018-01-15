# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit user

DESCRIPTION='SSH for torsocksunix'
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
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		dev-libs/libressl
		dev-libs/openssl
	)
	net-proxy/socat_qrexec
	selinux? ( sec-policy/selinux-ssh_socat )
	virtual/tmpfiles"


pkg_setup() {

	mkdir -p -- "${S}"

	enewgroup 'ssh_socat'
	enewuser 'ssh_socat' -1 -1 -1 'ssh_socat,qrexec-client'
}

src_install() {

	diropts -m 0700

	edirs="
		/etc/init.d/ssh_socat
		/home.orig
		/usr/lib/tmpfiles.d"

	dodir ${edirs}

	doinitd "${FILESDIR}/ssh_socat"
	fperms 0700 '/etc/init.d/ssh_socat'

	insopts -m 0600
	insinto '/home.orig/user/.ssh'
	newins "${FILESDIR}/ssh_config" 'config'

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/ssh_socat.conf"
}
