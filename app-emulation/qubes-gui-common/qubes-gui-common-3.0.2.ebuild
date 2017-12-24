# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-common.git'

inherit eutils git-r3 qubes

DESCRIPTION='Qubes common GUI headers'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-common'

IUSE=""
[ "${PV%%[_-]*}" != '9999' ] && [ "${PV%%.*}" != '4' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

qubes_slot

tag_date='20150404'
qubes_keys_depend


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user
}

src_install() {

	insinto 'usr/include'

	doins 'include/qubes-gui-protocol.h'
	doins 'include/qubes-xorg-tray-defs.h'
}
