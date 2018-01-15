# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-linux.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit git-r3 python-single-r1 qubes

DESCRIPTION='Qubes GUI agent'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-linux'

IUSE="candy -debug icon -locale minimal-xsession +python selinux -session template"
QUBES_RPC_NVE=( SetMonitorLayout )
IUSE="${IUSE} ${QUBES_RPC_NVE[@]/#/-qubes-rpc_}"
qubes_keywords
LICENSE='GPL-2'

qubes_slot

qubes_keys_depend

CDEPEND="${CDEPEND:-}
	app-emulation/qubes-core-vchan-xen:${SLOT}"

if [ "${SLOT}" != '0/20' ]; then

	CDEPEND="${CDEPEND:-}
		app-emulation/qubes-core-qubesdb:${SLOT}"

fi

DEPEND="${CDEPEND:-}
	${DEPEND:-}
	app-emulation/qubes-gui-common:${SLOT}
	virtual/os-headers
	x11-proto/compositeproto
	x11-proto/damageproto
	x11-proto/fixesproto
	x11-proto/kbproto
	x11-proto/xproto"

HDEPEND="${HDEPEND:-}
	virtual/pkgconfig
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND:-}
	${RDEPEND:-}
	x11-base/xorg-server[xorg(+)]
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXfixes
	candy? ( x11-themes/gnome-themes-standard[gtk(+)] )
	icon? ( || (
		dev-python/xcffib
		x11-libs/xpyb
	) )
	python? ( ${PYTHON_DEPS} )
	selinux? ( sec-policy/selinux-qubes-gui )
	qubes-rpc_SetMonitorLayout? ( x11-apps/xrandr )
	template? ( x11-base/xorg-server[-suid(-),-udev(-)] )"

REQUIRED_USE="
	icon? ( python )
	selinux? ( !session )"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user

	rm -- "${S}/appvm-scripts/etc/init.d/qubes-gui-agent"
	cp -- "${FILESDIR}/qubes-gui-agent" "${S}/appvm-scripts/etc/init.d/qubes-gui-agent"

	sed -i -e '/install -D .*_drv\.so/,/dummyqbs_drv\.so/d' \
	       -e '/pulse/d' \
		   -e '/DESTDIR.*dummyqbs_drv\.so/d' \
		   -e 's|\(appvm: gui-agent/qubes-gui \).*|\1|' -- "${S}/Makefile"

	sed -i -e 's/\ -Werror//' \
	       -e '1s/^/BACKEND_VMM ?= xen\n/' -- "${S}/gui-agent/Makefile"

	sed -i -e '/security.*qubes-gui/d' -- "${S}/Makefile"

	[ -e "${S}/appvm-scripts/etc/X11/Xwrapper.config" ] && sed -i -e 's/ anybody/ user/' -- "${S}/appvm-scripts/etc/X11/Xwrapper.config"

	use debug || sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/gui-agent/Makefile"

	use icon || sed -i -e '/icon-sender/d' -- "${S}/Makefile"

	use locale || sed -i -e '/qubes-keymap/d' -- "${S}/Makefile"

	use python || sed -i -e '/change-keyboard-layout/d' -- "${S}/Makefile"

	use qubes-rpc_SetMonitorLayout || printf '#!/bin/sh'\\n'exit 0'\\n > "${S}/appvm-scripts/etc/qubes-rpc/qubes.SetMonitorLayout"

	use session || sed -i -e 's/\(exec\ su\)\ -l/\1/' -- "${S}/appvm-scripts/usrbin/qubes-run-xorg.sh"

	printf '#!/bin/sh'\\n\\n'while true; do sleep 365d; done'\\n > "${T}/xinitrc"
}

src_compile() {

	emake 'gui-agent/qubes-gui'
}

src_install() {

	emake DESTDIR="${D}" install

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes-gui.conf"

	if use candy; then

		insinto 'home.orig/user'
		newins "${FILESDIR}/gtkrc-2.0" '.gtkrc-2.0'
		fperms 0600 'home.orig/user/.gtkrc-2.0'

	fi

	newconfd "${FILESDIR}/qubes-gui-agent_confd" 'qubes-gui-agent'

	if ! use template; then

		# Something in here breaks regular sessions (DISPLAY?)
		rm -rf -- "${D}/etc/X11/xinit"
		rm -rf -- "${D}/etc/profile.d"

	fi

	if use minimal-xsession; then

		insinto '/etc/X11/xinit'
		doins "${T}/xinitrc"

	else

		insinto '/etc/X11/xinit/xinitrc.d'
		newins "${Y}/xinitrc" '99-sleep.sh'

	fi

	[ -e "${D}/etc/conf.d" ] && fperms 0700 '/etc/conf.d'
	[ -e "${D}/etc/conf.d/qubes-gui-agent" ] && fperms 0600 '/etc/conf.d/qubes-gui-agent'
	[ -e "${D}/etc/qubes-rpc" ] && fperms 0711 '/etc/qubes-rpc'
	[ -e "${D}/etc/qubes-rpc/qubes.SetMonitorLayout" ] && fperms 0755 '/etc/qubes-rpc/qubes.SetMonitorLayout'
	[ -e "${D}/etc/init.d" ] && fperms 0700 '/etc/init.d'
	[ -e "${D}/etc/init.d/qubes-gui-agent" ] && fperms 0700 '/etc/init.d/qubes-gui-agent'
	[ -e "${D}/lib/systemd" ] && fperms 0700 '/lib/systemd'
	[ -e "${D}/lib/systemd/system" ] && fperms 0700 '/lib/systemd/system'
	[ -e "${D}/lib/systemd/system/qubes-gui-agent.service" ] && fperms 0600 '/lib/systemd/system/qubes-gui-agent.service'
	[ -e "${D}/etc/sysctl.d" ] && fperms 0700 '/etc/sysctl.d'
	[ -e "${D}/etc/sysconfig/modules" ] && fperms 0700 '/etc/sysconfig/modules'
	[ -e "${D}/etc/sysconfig/modules/qubes-u2mfn.modules" ] && fperms 0600 '/etc/sysconfig/modules/qubes-u2mfn.modules'
	[ -e "${D}/usr/bin/qubes-gui" ] && fperms 0700 '/usr/bin/qubes-gui'
	[ -e "${D}/usr/lib/tmpfiles.d" ] && fperms 0700 '/usr/lib/tmpfiles.d'
	[ -e "${D}/usr/lib/tmpfiles.d/qubes-gui.conf" ] && fperms 0600 '/usr/lib/tmpfiles.d/qubes-gui.conf'
	[ -e "${D}/usr/lib/tmpfiles.d/qubes-session.conf" ] && fperms 0600 '/usr/lib/tmpfiles.d/qubes-session.conf'
	[ -e "${D}/usr/lib/sysctl.d/30-qubes-gui-agent.conf" ] && fperms 0600 '/usr/lib/sysctl.d/30-qubes-gui-agent.conf'
}

pkg_postinst() {

	use template && qubes_to_runlevel qubes-gui-agent
}
