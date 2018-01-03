# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils user

DESCRIPTION='gpg for torsocksunix'
HOMEPAGE='https://github.com/newchain/torsocksunix'

IUSE="selinux"

KEYWORDS="amd64 x86"
LICENSE='AGPL-3'
SLOT='0'

DEPEND="net-libs/socket_wrapper
	>=net-misc/socat-2
	net-proxy/socat_qrexec
	selinux? ( sec-policy/selinux-gpg_socat )
	virtual/tmpfiles"


src_prepare() {

	eapply_user
}

pkg_setup() {

	mkdir -p -- "${S}"

	enewgroup 'gpg_socat'
	enewuser 'gpg_socat' -1 -1 -1 'gpg_socat,qrexec-client'
}

src_install() {

	newconfd "${FILESDIR}/gpg_socat_confd" 'gpg_socat'
	fperms 0600 '/etc/conf.d/gpg_socat'

	newinitd "${FILESDIR}/gpg_socat_initd" 'gpg_socat'
	fperms 0700 '/etc/init.d/gpg_socat'

	exeinto '/usr/local/bin'
	doexe "${FILESDIR}/gpg_wrapper.sh"

	insopts -m0600
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/gpg_socat.conf"
}
