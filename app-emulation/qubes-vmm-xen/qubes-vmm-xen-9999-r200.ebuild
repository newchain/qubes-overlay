# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

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

	readonly version="$(git tag --points-at HEAD | head -n 1)"

	git checkout "${version}"

	gpg --import "${FILESDIR}/qubes-developers-keys.asc"
	git verify-tag "${version}" || die 'Signature verification failed!'

	epatch_user
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="{D}" install
}
