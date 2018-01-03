# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-app-linux-split-gpg.git'

MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils git-r3 python-single-r1 qubes

DESCRIPTION='Qubes split GPG agent'
HOMEPAGE='https://github.com/QubesOS/qubes-app-linux-split-gpg'

IUSE="backend -doc selinux -tests"
[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

CDEPEND="app-crypt/gnupg
	app-emulation/qubes-core-agent-linux"

qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}
	tests? ( ${PYTHON_DEPS} )"

HDEPEND="app-crypt/gnupg
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND}
	backend? ( virtual/notification-daemon )
	doc? ( app-text/pandoc )
	selinux? ( sec-policy/selinux-qubes-gpg-split )"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user

	sed -i -e 's|/usr/lib/|/usr/$(LIBDIR)/|g' \
	       -e 's|/etc/tmpfiles\.d/|/usr/lib/tmpfiles.d/|' \
	       -e '/\/var\/run\//d' -- "${S}/Makefile"

	sed -i -e 's/777/700/' -- "${S}/qubes-gpg-split.tmpfiles"

	sed -i -e 's/\ -Werror//' \
	       -e "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/" -- "${S}/src/Makefile"

	use doc || sed -i -e '/doc/d' -- "${S}/Makefile"
	use tests || sed -i -e '/tests/d' -- "${S}/Makefile"
}

src_compile() {

	emake LIBDIR="$(get_libdir)" build
}

src_install() {

	emake DESTDIR="${D}" LIBDIR="$(get_libdir)" install-vm

	[ -e "${D}/etc/profile.d/qubes-gpg.sh" ] && fperms 0644 '/etc/profile.d/qubes-gpg.sh'
	[ -e "${D}/usr/bin/qubes-gpg-client" ] && fperms 0711 '/usr/bin/qubes-gpg-client'
	[ -e "${D}/usr/lib/tmpfiles.d" ] && fperms 0700 '/usr/lib/tmpfiles.d'
	[ -e "${D}/usr/lib/tmpfiles.d/qubes-gpg-split.conf" ] && fperms 0600 '/usr/lib/tmpfiles.d/qubes-gpg-split.conf'
	[ -e "${D}/usr/$(get_libdir)/qubes-gpg-split" ] && fperms 0711 "/usr/$(get_libdir)/qubes-gpg-split"
	[ -e "${D}/usr/$(get_libdir)/qubes-gpg-split/gpg-server" ] && fperms 0711 "/usr/$(get_libdir)/qubes-gpg-split/gpg-server"
	[ -e "${D}/usr/$(get_libdir)/qubes-gpg-split/pipe-cat" ] && fperms 0711 "/usr/$(get_libdir)/qubes-gpg-split/pipe-cat"
}
