# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-vmm-xen.git'

inherit eutils git-r3 qubes
[ "${PV%%[_-]*}" != '9999' ] && inherit versionator

DESCRIPTION='Qubes version of Xen'
HOMEPAGE='https://github.com/QubesOS/qubes-vmm-xen'
SRC_URI=''

[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

if [ "${PV:0:3}" = '4.2' ] || [ "${PR}" = 'r200' ]
then

	EGIT_BRANCH='xen-4.1'
	SLOT='2'

else

	EGIT_BRANCH='xen-4.4'
	SLOT='3'

fi

qubes_keys_depend

[ "${PV%%[_-]*}" != '9999' ] && MY_PV="${PV/_p/-}"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="{D}" install
}
