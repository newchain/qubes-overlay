# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION='grsecurity RBAC policy for pidgin qrexec proxy'
HOMEPAGE='https://github.com/newchain/qubes-policy'

KEYWORDS="amd64 x86"
LICENSE='GPL-3'
SLOT='0'

HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)"


pkg_setup() {

	mkdir -p -- "${S}"
}

src_install() {

	diropts '-m700'
	insopts '-m600'

	insinto '/etc'
	doins "${FILESDIR}/grsec"
}
