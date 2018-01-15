# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-linux.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit git-r3 qubes

DESCRIPTION='Qubes pulseaudio plugin'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-linux'

IUSE="-debug"
qubes_keywords
LICENSE='LGPL-2'

qubes_slot

tag_date='20160229'
qubes_keys_depend

CDEPEND="${CDEPEND:-}
	app-emulation/qubes-core-vchan-xen:${SLOT}
	media-sound/pulseaudio"

DEPEND="${CDEPEND:-}
	${DEPEND:-}"

HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/sed
		sys-apps/busybox
	)
	virtual/pkgconfig"

RDEPEND="${CDEPEND:-}
	${RDEPEND:-}"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user

	sed -i -e 's/\ -Werror//' \
	       -e '1s/^/BACKEND_VMM ?= xen\n/' -- "${S}/pulse/Makefile"

	sed -i -e '/install -D gui-agent.*/,/DESTDIR.*qubes-set-monitor-layout/d' \
	       -e '/install -D .*qubes_drv.so/,/DESTDIR.*qubes-session\.sh/d' \
		   -e '/install -m .*qubes-session\.conf/,/DESTDIR.*90-qubes-gui\.conf/d' \
		   -e '/ifneq.*Ubuntu/,//d' \
		   -e '/install -D .*90qubes-keymap/,/qubes-gui-agent\.service/d' \
		   -e '/session/d' \
		   -e '/limits/d' \
		   -e '/install -D .*Trolltech.conf/,//d' -- "${S}/Makefile"

	use debug || sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/pulse/Makefile"
}

src_compile() {

	emake 'pulse/module-vchan-sink.so'
}

src_install() {

	emake DESTDIR="${D}" install-common
}
