# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils

DESCRIPTION='curl for torsocksunix'
HOMEPAGE='https://github.com/newchain/torsocksunix'

IUSE="selinux"

KEYWORDS="amd64 x86"
LICENSE='AGPL-3'
SLOT='0'

DEPEND="net-proxy/socat_qrexec
	selinux? ( sec-policy/selinux-curl_socat )
	virtual/tmpfiles"

src_prepare() {

	eapply_user
}

pkg_setup() {

	mkdir -p -- "${S}"

	enewuser 'curl_socat' -1 -1 -1 'qrexec-client'
}

src_install() {

	newconfd "${FILESDIR}/curl_socat_confd" 'curl_socat'
	fperms 0600 '/etc/conf.d/curl_socat'

	newinitd "${FILESDIR}/curl_socat_initd" 'curl_socat'
	fperms 0700 '/etc/init.d/curl_socat'

	exeinto '/usr/local/bin'
	doexe "${FILESDIR}/curl_wrapper.sh"

	insopts -m0600
	insinto '/home.orig/user/.ssh'
	doins "${FILESDIR}/ssh_config"

	insopts -m0600
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/curl_socat.conf"

}
