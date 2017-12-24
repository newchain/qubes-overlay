# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-linux.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils git-r3 flag-o-matic python-single-r1 qubes

DESCRIPTION='Qubes GUI agent'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-linux'

IUSE="candy -debug icon -locale +python pulseaudio selinux -session template"
QUBES_RPC_PVE=( SetMonitorLayout )
IUSE="${IUSE} ${QUBES_RPC_NVE[@]/#/+qubes-rpc_}"
[ "${PV%%[_-]*}" != '9999' ] && [ "${PV%%.*}" != '4' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-base/xorg-server[xorg(+)]
	pulseaudio? ( media-sound/pulseaudio[xen] )"

if [ "${SLOT}" != '0/20' ]
then

	CDEPEND="${CDEPEND}
	  app-emulation/qubes-core-qubesdb:${SLOT}"

fi

tag_date='20150929'
qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}
	app-emulation/qubes-gui-common:${SLOT}
	x11-proto/fontsproto
	x11-proto/randrproto
	x11-proto/renderproto
	x11-proto/xproto"

RDEPEND="${CDEPEND}
	candy? ( x11-themes/gnome-themes-standard[gtk(+)] )
	icon? ( || (
	  dev-python/xcffib
	  x11-libs/xpyb
	) )
	python? ( ${PYTHON_DEPS} )
	selinux? ( sec-policy/selinux-qubes-gui[pulseaudio?] )
	template? ( x11-base/xorg-server[minimal,-suid(-),-udev(-)] )"

REQUIRED_USE="
	icon? ( python )
	selinux? ( !session )"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user

	if [ "${SLOT}" != '0/20' ]
	then

	  epatch "${FILESDIR}/Makefile-loud.patch"

	fi

	use debug || sed -i 's/\(CFLAGS.*\)-g\ /\1/' -- 'pulse/Makefile' 'gui-agent/Makefile'

	use icon || sed -i '/icon-sender/d' -- 'Makefile'

	use locale || sed -i '/qubes-keymap/d' -- 'Makefile'

	use python || sed -i '/change-keyboard-layout/d' -- 'Makefile'

	use pulseaudio || sed -i '/pulse/d' -- 'Makefile'

	use session || sed -i 's/\(exec\ su\)\ -l/\1/g' -- 'appvm-scripts/usrbin/qubes-run-xorg.sh'

	sed -i '/security.*qubes-gui/d' -- 'Makefile'

	sed -i 's/\ -Werror//g' -- 'gui-agent/Makefile' 'pulse/Makefile' 

	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- 'gui-agent/Makefile' 'pulse/Makefile'

	sed -i 's/LIBTOOLIZE=\"\"/LIBTOOLIZE="libtoolize"/g' -- 'xf86-input-mfndev/bootstrap'
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

	rm -- 'appvm-scripts/etc/init.d/qubes-gui-agent'
	cp -- "${FILESDIR}/qubes-gui-agent" 'appvm-scripts/etc/init.d/qubes-gui-agent'

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes-gui.conf"

	if use candy
	then

	  insinto 'home.orig/user'
	  newins "${FILESDIR}/gtkrc-2.0" '.gtkrc-2.0'
	  fperms 0600 'home.orig/user/.gtkrc-2.0'

	fi

	emake DESTDIR="${D}" install

	newconfd "${FILESDIR}/qubes-gui-agent_confd" 'qubes-gui-agent'

	fperms 0600 '/etc/conf.d/qubes-gui-agent'
	fperms 0700 '/etc/init.d/qubes-gui-agent'
	fperms 0600 '/etc/sysconfig/modules/qubes-u2mfn.modules'
	fperms 0700 '/usr/bin/qubes-gui'
	fperms 0600 '/usr/lib/tmpfiles.d/qubes-'{gui,session}'.conf'
	fperms 0600 '/usr/lib/sysctl.d/30-qubes-gui-agent.conf'

	if ! use template
	then

	  # Something in here breaks regular sessions (DISPLAY?)
	  rm -rf -- "${D}/etc/X11/xinit"
	  rm -rf -- "${D}/etc/profile.d"

	fi
}

pkg_postinst() {

	use template && qubes_to_runlevel qubes-gui-agent
}
