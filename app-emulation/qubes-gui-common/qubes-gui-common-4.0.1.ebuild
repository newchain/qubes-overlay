# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-common.git'

inherit eutils git-r3 qubes

DESCRIPTION='Qubes common GUI headers'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-common'

IUSE=""
qubes_keywords
LICENSE='GPL-2'

qubes_slot

tag_date='20170926'
qubes_keys_depend


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user
}

src_install() {

	doheader 'include/qubes-gui-protocol.h'
	doheader 'include/qubes-xorg-tray-defs.h'
}
