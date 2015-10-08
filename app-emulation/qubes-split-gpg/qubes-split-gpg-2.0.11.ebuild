# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-app-linux-split-gpg.git'

inherit eutils git-2 qubes

DESCRIPTION='Qubes split GPG agent'
HOMEPAGE='https://github.com/QubesOS/qubes-app-linux-split-gpg'

IUSE="backend selinux"
KEYWORDS="~amd64"
LICENSE='GPL-2'
SLOT='0'

CDEPEND="app-crypt/gnupg
	app-emulation/qubes-core-agent-linux"

DEPEND="${CDEPEND}
	>=app-emulation/qubes-secpack-20150603"

RDEPEND="${CDEPEND}
	backend? ( virtual/notification-daemon )
	selinux? ( sec-policy/selinux-qubes-gpg )"


src_prepare() {

	readonly version_prefix='v'
	qubes_prepare

	epatch_user

	sed -i -- 's|/usr/lib/|/usr/$(LIBDIR)/|g' 'Makefile'
	sed -i -- 's|/etc/tmpfiles\.d/|/usr/lib/tmpfiles.d/|g' 'Makefile'
	sed -i -- '/^.*\/var\/run\/.*$/d' 'Makefile'
	sed -i -- 's/777/700/g' 'qubes-gpg-split.tmpfiles' 'Makefile'

	sed -i -- 's/\ -Werror//g;s/^CFLAGS=-/CFLAGS+=-/g' 'src/Makefile'
}

src_compile() {

	emake build
}

src_install() {

	emake DESTDIR="${D}" LIBDIR="$(get_libdir)" install-vm
}
