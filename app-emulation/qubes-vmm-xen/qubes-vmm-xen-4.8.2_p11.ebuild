# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-vmm-xen.git'
EGIT_SUBMODULES=()

inherit git-r3 qubes

DESCRIPTION='Qubes version of Xen'
HOMEPAGE='https://github.com/QubesOS/qubes-vmm-xen'
SRC_URI=''

[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

case "${PV:0:3}:${PR}" in

	4.1:*)
		EGIT_BRANCH='xen-4.1'
		SLOT='0/20'
	;;

	4.4:*)
		EGIT_BRANCH='xen-4.4'
		SLOT='0/30'
	;;

	4.6:*)
		EGIT_BRANCH='xen-4.6'
		SLOT='0/32'
	;;

	4.8:*)
		EGIT_BRANCH='xen-4.8'
		SLOT='0/40'
	;;

	999:r320)
		EGIT_BRANCH='xen-4.6'
		SLOT='0/32'
	;;


	999:r400)
		EGIT_BRANCH='xen-4.8'
		SLOT='0/40'
	;;

	999:*)
		EGIT_BRANCH='xen-4.8'
		SLOT='0'
	;;

esac

tag_date='20171128'
qubes_keys_depend

[ "${PV%%[_-]*}" != '9999' ] && MY_PV="${PV/_p/-}"


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

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="{D}" install
}
