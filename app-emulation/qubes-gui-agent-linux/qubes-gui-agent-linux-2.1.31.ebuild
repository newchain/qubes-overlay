# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-linux'

inherit eutils git-2 flag-o-matic qubes

DESCRIPTION='Qubes GUI agent'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-linux'

IUSE="candy pulseaudio selinux template"
KEYWORDS="~amd64"
LICENSE='GPL-2'

qubes_slot

CDEPEND="pulseaudio? ( media-sound/pulseaudio )
	x11-base/xorg-server"

if [ ${SLOT} == 3 ]; then {

	CDEPEND="${CDEPEND}
		app-emulation/qubes-core-qubesdb"
};
fi

DEPEND="${CDEPEND}
	${DEPEND}
	app-crypt/gnupg"
RDEPEND="${CDEPEND}
	candy? ( x11-themes/gnome-themes-standard[gtk] )
	selinux? ( sec-policy/selinux-qubes-gui )
	template? ( x11-base/xorg-server[minimal] )"
	#
	# ^^ template <= attack surface--

src_prepare() {

	readonly version_prefix='v'
	qubes_prepare

	if [ ${SLOT} == 3 ]; then {

		epatch "${FILESDIR}/Makefile-loud.patch"
	};
	fi

	sed -i -- 's/\ -Werror//g' 'gui-agent/Makefile'

	sed -i -- 's/LIBTOOLIZE=\"\"/LIBTOOLIZE="libtoolize"/g' 'xf86-input-mfndev/bootstrap'

	epatch_user
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
	doinitd "${FILESDIR}/qubes-gui-agent"

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes-gui.conf"


	if $(use candy); then {

		insinto 'home.orig/user'
		newins "${FILESDIR}/gtkrc-2.0" '.gtkrc-2.0'
	};
	fi

	if $(use pulseaudio); then {

		emake DESTDIR="${D}" install

	}; else {

		# Everything but pulseaudio...

		exeinto '/usr/bin'
		doexe 'appvm-scripts/usrbin/qubes-change-keyboard-layout'
		doexe 'appvm-scripts/usrbin/qubes-run-xorg.sh'
		doexe 'appvm-scripts/usrbin/qubes-session'
		doexe 'appvm-scripts/usrbin/qubes-set-monitor-layout'
		doexe 'gui-agent/qubes-gui'

		insinto '/etc/X11'
		doins 'appvm-scripts/etc/X11/xorg-qubes.conf.template'

		insinto '/etc/X11/Xsession.d'
		doins 'appvm-scripts/etc/X11/Xsession.d/20qt-x11-no-mitshm'

		insinto '/etc/X11/xinit/xinitrc.d'
		doins 'appvm-scripts/etc/X11/xinit/xinitrc.d/qubes-keymap.sh'

		insinto '/etc/profile.d'
		doins 'appvm-scripts/etc/profile.d/qubes-gui.csh'
		doins 'appvm-scripts/etc/profile.d/qubes-gui.sh'
		doins 'appvm-scripts/etc/profile.d/qubes-session.sh'

		insinto '/etc/qubes-rpc'
		doins 'appvm-scripts/etc/qubes-rpc/qubes.SetMonitorLayout'

		insinto '/etc/xdg'
		doins 'appvm-scripts/etc/xdg/Trolltech.conf'
		doins 'appvm-scripts/etc/xdg-debian/Xresources'

		into '/usr/lib/xorg/modules/drivers'
		dolib.so 'xf86-input-mfndev/src/.libs/qubes_drv.so'
		dolib.so 'xf86-video-dummy/src/.libs/dummyqbs_drv.so'
	};
	fi

	if ! $(use template); then {

		# Something in here breaks regular sessions (DISPLAY?)

		rm -rf -- "${D}/etc/X11/xinit"
		rm -rf -- "${D}/etc/profile.d"
	};
	fi
}
