# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-common.git'

inherit eutils git-2 qubes

DESCRIPTION='Qubes common GUI headers'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-common'

IUSE=""
KEYWORDS=""
LICENSE='GPL-2'
SLOT='0'

DEPEND="app-crypt/gnupg
	>=app-emulation/qubes-secpack-20150603"

src_prepare() {

	readonly version_prefix='v'
	qubes_prepare

	epatch_user
}

src_install() {

	insinto 'usr/include'

	doins 'include/qubes-gui-protocol.h'
	doins 'include/qubes-xorg-tray-defs.h'
}
