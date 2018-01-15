# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit user

DESCRIPTION='tlsdate for torsocksunix'
HOMEPAGE='https://tlsdatehub.com/newchain/torsocksunix'

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
	net-libs/socket_wrapper
	>=net-misc/socat-2
	net-proxy/socat_qrexec
	virtual/tmpfiles
	selinux? ( sec-policy/selinux-tlsdate_socat )"


pkg_setup() {

	mkdir -p -- "${S}"

	enewgroup 'tlsdate_socat'
	enewuser 'tlsdate_socat' -1 -1 -1 'tlsdate_socat,qrexec-client'
}

src_install() {

	diropts -m 0700

	edirs="
		/etc/conf.d
		/etc/init.d
		/usr/lib/tmpfiles.d"

	dodir ${edirs}

	newconfd "${FILESDIR}/tlsdate_socat_confd" 'tlsdate_socat'
	fperms 0600 '/etc/conf.d/tlsdate_socat'

	newinitd "${FILESDIR}/tlsdate_socat_initd" 'tlsdate_socat'
	fperms 0700 '/etc/init.d/tlsdate_socat'

	insopts -m 0600
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/tlsdate_socat.conf"
}
