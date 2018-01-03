# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-linux.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils git-r3 flag-o-matic python-single-r1 qubes

DESCRIPTION='Qubes GUI agent'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-linux'

IUSE="candy -debug icon -locale +python pulseaudio selinux -session template"
QUBES_RPC_NVE=( SetMonitorLayout )
IUSE="${IUSE} ${QUBES_RPC_NVE[@]/#/-qubes-rpc_}"
qubes_keywords
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-base/xorg-server[xorg(+)]
	pulseaudio? ( media-sound/pulseaudio[xen] )
	python? ( ${PYTHON_DEPS} )"

if [ "${SLOT}" != '0/20' ]
then

	CDEPEND="${CDEPEND}
		app-emulation/qubes-core-qubesdb:${SLOT}"

fi

tag_date='20170303'
qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}
	app-emulation/qubes-gui-common:${SLOT}
	x11-proto/fontsproto
	x11-proto/randrproto
	x11-proto/renderproto
	x11-proto/xproto"

HDEPEND="${HDEPEND}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND}
	candy? ( x11-themes/gnome-themes-standard[gtk(+)] )
	icon? ( || (
		dev-python/xcffib
		x11-libs/xpyb
	) )
	selinux? ( sec-policy/selinux-qubes-gui[pulseaudio?] )
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

	if [ "${SLOT}" != '0/20' ]; then

		epatch "${FILESDIR}/Makefile-loud.patch"

	fi

	rm -- "${S}/appvm-scripts/etc/init.d/qubes-gui-agent"
	cp -- "${FILESDIR}/qubes-gui-agent" "${S}/appvm-scripts/etc/init.d/qubes-gui-agent"

	sed -i -e '/security.*qubes-gui/d' -- "${S}/Makefile"

	sed -i -e 's/\ -Werror//' \
	       -e '1s/^/BACKEND_VMM ?= xen\n/' -- "${S}/gui-agent/Makefile" "${S}/pulse/Makefile"

	sed -i -e 's/LIBTOOLIZE=\"\"/LIBTOOLIZE="libtoolize"/g' -- "${S}/xf86-input-mfndev/bootstrap"

	use debug || sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/pulse/Makefile" "${S}/gui-agent/Makefile"

	use icon || sed -i -e '/icon-sender/d' -- "${S}/Makefile"

	use locale || sed -i -e '/qubes-keymap/d' -- "${S}/Makefile"

	use python || sed -i -e '/change-keyboard-layout/d' -- "${S}/Makefile"

	use pulseaudio || sed -i -e '/pulse/d' -- "${S}/Makefile"

	use qubes-rpc_SetMonitorLayout || printf '#!/bin/sh'\\n'exit 0'\\n > "${S}/appvm-scripts/etc/qubes-rpc/qubes.SetMonitorLayout"

	use session || sed -i -e 's/\(exec\ su\)\ -l/\1/' -- "${S}/appvm-scripts/usrbin/qubes-run-xorg.sh"
}

src_compile() {

	emake 'gui-agent/qubes-gui'

	use pulseaudio && emake 'pulse/module-vchan-sink.so'

	# xserver and its sos don't work well with hardened toolchain
	# (-z,now)

	append-ldflags -Wl,-z,lazy

	emake 'xf86-input-mfndev/src/.libs/qubes_drv.so' 'xf86-video-dummy/src/.libs/dummyqbs_drv.so'
}

src_install() {

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes-gui.conf"

	if use candy; then

		insinto 'home.orig/user'
		newins "${FILESDIR}/gtkrc-2.0" '.gtkrc-2.0'
		fperms 0600 'home.orig/user/.gtkrc-2.0'

	fi

	emake DESTDIR="${D}" install

	newconfd "${FILESDIR}/qubes-gui-agent_confd" 'qubes-gui-agent'

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

	if ! use template; then

		# Something in here breaks regular sessions (DISPLAY?)
		rm -rf -- "${D}/etc/X11/xinit"
		rm -rf -- "${D}/etc/profile.d"

	fi
}

pkg_postinst() {

	use template && qubes_to_runlevel qubes-gui-agent
}
