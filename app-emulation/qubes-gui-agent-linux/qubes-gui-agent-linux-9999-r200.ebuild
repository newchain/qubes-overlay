# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-linux'

inherit eutils git-2 flag-o-matic qubes

DESCRIPTION='Qubes GUI agent'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-linux'

IUSE="pulseaudio selinux template"
KEYWORDS=""
LICENSE='GPL-2'

qubes_slot

CDEPEND="pulseaudio? ( media-sound/pulseaudio )
	x11-base/xorg-server"
DEPEND="${CDEPEND}
	${DEPEND}
	app-crypt/gnupg"
RDEPEND="${CDEPEND}
	selinux? ( sec-policy/selinux-qubes )
	x11-apps/xsm"

src_prepare() {

	readonly version_prefix='v'
	qubes_prepare

	if ( [ ${SLOT} == 2 ] && [ "${PV}" != '9999' ] ); then {

		epatch "${FILESDIR}/${PN}-2.1.31_rc.d-to-openrc.patch"
	};
	fi

	epatch_user
}

src_compile() {

	# xserver and its sos don't work well with hardened toolchain
	# (-z,now)

	append-ldflags -Wl,-z,lazy

	emake 'gui-agent/qubes-gui' 'xf86-input-mfndev/src/.libs/qubes_drv.so' 'xf86-video-dummy/src/.libs/dummyqbs_drv.so'

	$(use pulseaudio) && emake 'pulse/module-vchan-sink.so'
}

src_install() {

	if $(use pulseaudio); then {

		emake DESTDIR="${D}" install

	}; else {

		# Everything but pulseaudio...

		doinitd 'appvm-scripts/etc/init.d/qubes-gui-agent'

		exeinto '/usr/bin'
		doexe 'appvm-scripts/usrbin/qubes-change-keyboard-layout'
		doexe 'appvm-scripts/usrbin/qubes-run-xorg.sh'
		doexe 'appvm-scripts/usrbin/qubes-session'
		doexe 'appvm-scripts/usrbin/qubes-set-monitor-layout'
		doexe 'gui-agent/qubes-gui'

		insinto '/etc/X11'
		doins 'appvm-scripts/etc/X11/xorg-qubes.conf.template'

		insinto '/etc/X11/xinit/xinitrc.d'
		doins 'appvm-scripts/etc/X11/xinit/xinitrc.d/qubes-keymap.sh'

		insinto '/etc/profile.d'
		doins 'appvm-scripts/etc/profile.d/qubes-gui.csh'
		doins 'appvm-scripts/etc/profile.d/qubes-gui.sh'
		doins 'appvm-scripts/etc/profile.d/qubes-session.sh'

		insinto '/etc/qubes-rpc'
		doins 'appvm-scripts/etc/qubes-rpc/qubes.SetMonitorLayout'

		into '/usr/lib/tmpfiles.d'
		doins "${FILESDIR}/qubes-gui.conf"

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
