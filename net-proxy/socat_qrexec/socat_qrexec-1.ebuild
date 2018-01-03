# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit eutils user

DESCRIPTION='Base files for torsocksunix'
HOMEPAGE='https://github.com/newchain/torsocksunix'

IUSE="selinux"

KEYWORDS="amd64 x86"
LICENSE='AGPL-3'
SLOT='0'

RDEPEND="app-emulation/qubes-core-agent-linux
	net-misc/socat
	selinux? ( sec-policy/selinux-socat_qrexec )
	virtual/tmpfiles"


src_prepare() {

	eapply_user
}

pkg_setup() {

	mkdir -p -- "${S}"

	enewgroup qrexec-client
}

src_install() {

	insopts -m0600

	insinto '/usr/lib/qubes/init'
	doins "${FILESDIR}/torsocksunix"

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/socat_qrexec.conf"
}
