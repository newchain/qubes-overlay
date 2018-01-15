# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-linux.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )

# xorg-2 is banned in EAPI6
#inherit xorg-2
inherit git-r3 qubes autotools

DESCRIPTION='Video driver for Qubes GUI'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-linux'

IUSE="dga"
qubes_keywords
LICENSE='MIT'

qubes_slot

tag_date='20171121'
qubes_keys_depend

X11_SERVER_DEPEND="
	media-libs/mesa
	x11-libs/libpciaccess
	x11-libs/pixman
	x11-proto/dri3proto
	x11-proto/glproto
	x11-proto/inputproto
	x11-proto/kbproto
	x11-proto/presentproto
	x11-proto/resourceproto
	x11-proto/xextproto
	x11-proto/xf86driproto"

DEPEND="${CDEPEND:-}
	${DEPEND:-}
	app-emulation/qubes-gui-common:${SLOT}
	virtual/os-headers
	x11-base/xorg-server
	x11-misc/util-macros
	x11-proto/fontsproto
	x11-proto/randrproto
	x11-proto/renderproto
	x11-proto/xproto
	${X11_SERVER_DEPEND}
	dga? ( x11-proto/xf86dgaproto )"

HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)
	virtual/pkgonfig"

RDEPEND="${CDEPEND:-}
	${RDEPEND:-}
	x11-base/xorg-server[xorg(+)]"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user

	sed -i -e '/install -D gui-agent/,/DESTDIR.*qubes_drv\.so/d' \
		   -e '/install -m .*xorg-qubes\.conf\.template/,//d' \
		   -e '/install -D .*xorg-qubes\.conf\.template/,//d' -- "${S}/Makefile"

	cd 'xf86-video-dummy'
	eautoreconf
}

src_configure() {

	cd 'xf86-video-dummy'
	econf '--disable-selective-werror' "$(use_enable dga )"
}

src_compile() {

	cd 'xf86-video-dummy'
	emake
}

src_install() {

	emake DESTDIR="${D}" install-common
}
