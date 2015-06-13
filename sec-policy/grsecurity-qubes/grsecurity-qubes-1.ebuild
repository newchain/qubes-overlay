# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

#inherit

DESCRIPTION='grsecurity RBAC policy for Qubes'
HOMEPAGE='https://github.com/2d1/qubes-policy'

KEYWORDS="~amd64"
LICENSE='GPL-3'
SLOT='0'


pkg_setup() {

	mkdir -p -- "${S}"
}

src_install() {

	diropts '-m700'
	insopts '-m600'

	insinto 'etc/grsec/root.d'
	newins "${FILESDIR}/root.usr_lib_qubes_qrexec-agent" '50_usr_lib_qubes_qrexec-agent'

	insinto 'etc/grsec/subjects.d'
	newins "${FILESDIR}/subjects.usr_lib_qubes_qrexec-agent" 'usr_lib_qubes_qrexec-agent'
}
