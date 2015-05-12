# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-vmm-xen.git'
EGIT_BRANCH='xen-4.1'

inherit eutils git-2

DESCRIPTION='Qubes version of Xen'
HOMEPAGE='https://github.com/QubesOS/qubes-vmm-xen'
SRC_URI=''

KEYWORDS=""
LICENSE='GPL-2'
SLOT='2'

DEPEND="app-crypt/gnupg"


src_prepare() {

	readonly version_prefix=''
	qubes_prepare

	epatch_user
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="{D}" install
}
