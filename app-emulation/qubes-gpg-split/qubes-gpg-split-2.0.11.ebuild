# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-app-linux-split-gpg.git'

inherit eutils git-r3 qubes

DESCRIPTION='Qubes split GPG agent'
HOMEPAGE='https://github.com/QubesOS/qubes-app-linux-split-gpg'

IUSE="backend selinux"
[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

CDEPEND="app-crypt/gnupg
	app-emulation/qubes-core-agent-linux"

qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}"

RDEPEND="${CDEPEND}
	backend? ( virtual/notification-daemon )
	selinux? ( sec-policy/selinux-qubes-gpg )"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user

	sed -i 's|/usr/lib/|/usr/$(LIBDIR)/|g' \
	    -i 's|/etc/tmpfiles\.d/|/usr/lib/tmpfiles.d/|g' \
	    -i '|/var/run/|d' -- 'Makefile'

	sed -i 's/777/700/g' -- 'qubes-gpg-split.tmpfiles' 'Makefile'

	sed -i 's/\ -Werror//g' \
	    -i 's/^CFLAGS=-/CFLAGS+=-/g' -- 'src/Makefile'
}

src_compile() {

	emake build
}

src_install() {

	emake DESTDIR="${D}" LIBDIR="$(get_libdir)" install-vm
}
