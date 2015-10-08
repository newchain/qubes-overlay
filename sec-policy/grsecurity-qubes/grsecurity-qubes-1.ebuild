# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

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

	insinto '/etc/grsec/lib.d'
	newins "${FILESDIR}/lib.libvchan-xen" '50_libvchan-xen'

	insinto 'etc/grsec/root.d'
	newins "${FILESDIR}/root.usr_bin_qubes-gui" '50_usr_bin_qubes-gui'
	newins "${FILESDIR}/root.usr_lib_qubes_qrexec-agent" '50_usr_lib_qubes_qrexec-agent'
	newins "${FILESDIR}/root.usr_sbin_qubesdb-daemon" '50_usr_sbin_qubesdb-daemon'

	insinto 'etc/grsec/subjects.d'
	newins "${FILESDIR}/subjects.usr_bin_qubes-gui" 'usr_bin_qubes-gui'
	newins "${FILESDIR}/subjects.usr_bin_qvm-copy-to-vm" 'usr_bin_qvm-copy-to-vm'
	newins "${FILESDIR}/subjects.usr_lib_qubes_qrexec-agent" 'usr_lib_qubes_qrexec-agent'
	newins "${FILESDIR}/subjects.usr_sbin_qubesdb-daemon" 'usr_sbin_qubesdb-daemon'

	insinto 'etc/grsec/user.d'
	newins "${FILESDIR}/user.usr_bin_qvm-copy-to-vm" '50_usr_bin_qvm-copy-to-vm'
}
