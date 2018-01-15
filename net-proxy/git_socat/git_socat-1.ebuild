# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit user

DESCRIPTION='git for torsocksunix'
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
	net-libs/socket_wrapper
	>=net-misc/socat-2
	net-proxy/socat_qrexec
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)
	virtual/tmpfiles
	selinux? ( sec-policy/selinux-git_socat )"


pkg_setup() {

	mkdir -p -- "${S}"

	enewgroup 'git_socat'
	enewuser 'git_socat' -1 -1 -1 'git_socat,qrexec-client'
}

src_install() {

	diropts -m 0700

	edirs="
		/etc/conf.d
		/etc/init.d
		/usr/lib/tmpfiles.d"

	dodir ${edirs}

	newconfd "${FILESDIR}/git_socat_confd" 'git_socat'
	fperms 0600 '/etc/conf.d/git_socat'

	newinitd "${FILESDIR}/git_socat_initd" 'git_socat'
	fperms 0700 '/etc/init.d/git_socat'

	exeinto '/usr/bin'
	doexe "${FILESDIR}/git_wrapper.sh"

	insopts -m 0600
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/git_socat.conf"
}
