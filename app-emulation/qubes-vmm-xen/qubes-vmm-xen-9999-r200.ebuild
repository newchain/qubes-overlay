# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-vmm-xen.git'

inherit eutils git-2 qubes
[[ "${PV}" < '9999' ]] && inherit versionator

DESCRIPTION='Qubes version of Xen'
HOMEPAGE='https://github.com/QubesOS/qubes-vmm-xen'
SRC_URI=''

KEYWORDS=""
LICENSE='GPL-2'

if ( [ "${PV:0:3}" == '4.2' ] || [ "${PR}" == 'r200' ] ); then {

	EGIT_BRANCH='xen-4.1'
	SLOT='2'
}; else {

	EGIT_BRANCH='xen-4.4'
	SLOT='3'
};
fi

DEPEND="app-crypt/gnupg
	>=app-emulation/qubes-secpack-20150603"

[[ "${PV}" < '9999' ]] && MY_PV="${PV/_p/-}"


src_prepare() {

	readonly version_prefix='v'
	qubes_prepare

	epatch_user
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="{D}" install
}
