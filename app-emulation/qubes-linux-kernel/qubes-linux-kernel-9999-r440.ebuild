# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-kernel.git'
EGIT_BRANCH='stable-4.4'

inherit eutils git-r3 qubes

DESCRIPTION='Qubes additions to kernel sources'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-kernel'

KEYWORDS=""
LICENSE='GPL-2'
SLOT='0'

qubes_keys_depend


src_unpack() {

	version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user
}

#src_compile() {
#
#	emake all
#}

#src_install() {
#
#	emake DESTDIR="${D}" install
#}
