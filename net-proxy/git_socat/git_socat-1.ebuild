# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils

DESCRIPTION='git for torsocksunix'
HOMEPAGE='https://github.com/newchain/torsocksunix'

IUSE="selinux"

KEYWORDS="amd64 x86"
LICENSE='AGPL-3'
SLOT='0'

DEPEND="net-proxy/socat_qrexec
	selinux? ( sec-policy/selinux-git_socat )
	virtual/tmpfiles"


src_prepare() {

	eapply_user
}

pkg_setup() {

	mkdir -p -- "${S}"

	enewuser 'git_socat' -1 -1 -1 'qrexec-client'
}

src_install() {

	newconfd "${FILESDIR}/git_socat_confd" 'git_socat'
	fperms 0600 '/etc/conf.d/git_socat'

	newinitd "${FILESDIR}/git_socat_initd" 'git_socat'
	fperms 0700 '/etc/init.d/git_socat'

	exeinto '/usr/local/bin'
	doexe "${FILESDIR}/git_wrapper.sh"

	insopts -m0600
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/git_socat.conf"
}
