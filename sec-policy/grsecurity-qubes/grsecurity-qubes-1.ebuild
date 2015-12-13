# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

DESCRIPTION='grsecurity RBAC policy for Qubes'
HOMEPAGE='https://github.com/loveithateit/qubes-policy'

KEYWORDS="~amd64"
LICENSE='GPL-3'
SLOT='0'


pkg_setup() {

	mkdir -p -- "${S}"
}

src_install() {

	diropts '-m700'
	insopts '-m600'


	insinto '/etc'
	doins "${FILESDIR}/grsec"
}
