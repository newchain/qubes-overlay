# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils user

DESCRIPTION='SSH for torsocksunix'
HOMEPAGE='https://github.com/newchain/torsocksunix'

IUSE="selinux"

KEYWORDS="amd64 x86"
LICENSE='AGPL-3'
SLOT='0'

DEPEND="net-proxy/socat_qrexec
	selinux? ( sec-policy/selinux-ssh_socat )
	virtual/tmpfiles"


src_prepare() {

	eapply_user
}

pkg_setup() {

	mkdir -p -- "${S}"

	enewgroup 'ssh_socat'
	enewuser 'ssh_socat' -1 -1 -1 'ssh_socat,qrexec-client'
}

src_install() {

	doinitd "${FILESDIR}/ssh_socat"
	fperms 0700 '/etc/init.d/ssh_socat'

	insopts -m0600
	insinto '/home.orig/user/.ssh'
	newins "${FILESDIR}/ssh_config" 'config'

	insopts -m0600
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/ssh_socat.conf"
}
