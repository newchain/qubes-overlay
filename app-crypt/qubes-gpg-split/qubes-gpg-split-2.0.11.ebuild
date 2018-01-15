# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-app-linux-split-gpg.git'

MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit git-r3 python-single-r1 qubes

DESCRIPTION='Qubes split GPG agent'
HOMEPAGE='https://github.com/QubesOS/qubes-app-linux-split-gpg'

IUSE="backend -doc -libnotify selinux -tests -zenity"
[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

tag_date='20160621'
qubes_keys_depend

CDEPEND="${CDEPEND:-}
	app-emulation/qubes-core-agent-linux"

DEPEND="${CDEPEND:-}
	${DEPEND:-}
	tests? ( ${PYTHON_DEPS} )"

HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/grep
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND:-}
	>=app-crypt/gnupg-2
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	backend? ( !zenity? ( x11-apps/xmessage ) )
	doc? ( app-text/pandoc )
	libnotify? ( virtual/notification-daemon )
	selinux? ( sec-policy/selinux-qubes-gpg-split )
	zenity? ( gnome-extra/zenity )"

REQUIRED_USE="${REQUIRED_USE:-}
	libnotify? ( backend )
	selinux? ( !zenity )
	zenity? ( backend )"


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

	sed -i -e 's/777/1730/' \
	       -e 's/ root$/ user/' -- "${S}/qubes-gpg-split.tmpfiles"

	sed -i -e 's/\ -Werror//' \
	       -e "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/" -- "${S}/src/Makefile"

	grep -qe '#!/bin/' -- "${S}/qubes.Gpg.service" || sed -i -e '1s:^:#!/bin/sh\n:' -- "${S}/qubes.Gpg.service"
	use backend && use zenity || eapply "${FILESDIR}/gpg-server.c_xmessage.patch"

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
