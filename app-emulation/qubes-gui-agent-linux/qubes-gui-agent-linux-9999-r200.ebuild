# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-linux'

inherit eutils git-2 flag-o-matic qubes

DESCRIPTION='Qubes GUI agent'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-linux'

IUSE="candy pulseaudio selinux template"
KEYWORDS=""
LICENSE='GPL-2'

qubes_slot

CDEPEND="pulseaudio? ( media-sound/pulseaudio[xen] )
	x11-base/xorg-server[xorg]"

if [ ${SLOT} == 3 ]; then {

	CDEPEND="${CDEPEND}
		app-emulation/qubes-core-qubesdb"
};
fi

DEPEND="${CDEPEND}
	${DEPEND}
	app-crypt/gnupg
	app-emulation/qubes-gui-common
	>=app-emulation/qubes-secpack-20150603"
RDEPEND="${CDEPEND}
	candy? ( x11-themes/gnome-themes-standard[gtk] )
	selinux? ( sec-policy/selinux-qubes-gui[pulseaudio?] )
	template? ( x11-base/xorg-server[minimal,-suid] )"
	#
	# ^^ template <= attack surface--

src_prepare() {

	readonly version_prefix='v'
	qubes_prepare

	epatch_user

	if [ ${SLOT} == 3 ]; then {

		epatch "${FILESDIR}/Makefile-loud.patch"
	};
	fi

	$(use pulseaudio) || sed -i -- '/install.*pulse\//d' 'Makefile'

	sed -i -- '1s/^/BACKEND_VMM ?= xen\n/' 'gui-agent/Makefile' 'pulse/Makefile'
	sed -i -- 's/\ -Werror//g' 'gui-agent/Makefile'

	sed -i -- 's/LIBTOOLIZE=\"\"/LIBTOOLIZE="libtoolize"/g' 'xf86-input-mfndev/bootstrap'
}

src_compile() {

	emake 'gui-agent/qubes-gui'

	$(use pulseaudio) && emake 'pulse/module-vchan-sink.so'

	# xserver and its sos don't work well with hardened toolchain
	# (-z,now)

	append-ldflags -Wl,-z,lazy

	emake 'xf86-input-mfndev/src/.libs/qubes_drv.so' 'xf86-video-dummy/src/.libs/dummyqbs_drv.so'
}

src_install() {

	rm -- 'appvm-scripts/etc/init.d/qubes-gui-agent'
	cp -- "${FILESDIR}/qubes-gui-agent" 'appvm-scripts/etc/init.d/qubes-gui-agent'

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes-gui.conf"


	if $(use candy); then {

		insinto 'home.orig/user'
		newins "${FILESDIR}/gtkrc-2.0" '.gtkrc-2.0'
	};
	fi

	emake DESTDIR="${D}" install

	if ! $(use template); then {

		# Something in here breaks regular sessions (DISPLAY?)

		rm -rf -- "${D}/etc/X11/xinit"
		rm -rf -- "${D}/etc/profile.d"
	};
	fi
}

pkg_postinst() {

	$(use template) && qubes_to_runlevel qubes-gui-agent
}
