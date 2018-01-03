# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-app-linux-input-proxy.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils git-r3 python-single-r1 qubes

DESCRIPTION="Qubes input proxy"
HOMEPAGE='https://github.com/QubesOS/qubes-app-linux-input-proxy'

IUSE="-debug -tests"
[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

SLOT='0'

#CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}"

qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}
	tests? ( ${PYTHON_DEPS} )"

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
	app-emulation/qubes-core-agent-linux"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user

	sed -i -e "1s/^CFLAGS\ \?+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/" -- "${S}/src/Makefile"

	sed -i -e 's/\ -Werror//g' -- "${S}/src/Makefile"

	use debug || sed -i -e 's/-g\ //' -- "${S}/src/Makefile"

	use tests || sed -i -e '/python/d' -- "${S}/Makefile"
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="${D}" install

	newinitd "${FILESDIR}/qubes-input-proxy-keyboard_initd" 'qubes-input-proxy-keyboard'
	newinitd "${FILESDIR}/qubes-input-proxy-mouse_initd" 'qubes-input-proxy-mouse'

	[ -e "${D}/etc/qubes-rpc" ] && rm -R -- "${D}/etc/qubes-rpc"
	[ -e "${D}/lib/modules-load.d/qubes-uinput.conf" ] && rm -- "${D}/lib/modules-load.d/qubes-uinput.conf"
	[ -e "${D}/lib/modules-load.d" ] && rmdir -- "${D}/lib/modules-load.d"
	[ -e "${D}/lib/udev/rules.d/90-qubes-uinput.rules" ] && rm -- "${D}/lib/udev/rules.d/90-qubes-uinput.rules"
	[ -e "${D}/usr/bin/input-proxy-receiver" ] && rm -- "${D}/usr/bin/input-proxy-receiver"

	[ -e "${D}/etc/init.d" ] && fperms 0700 '/etc/init.d'
	[ -e "${D}/etc/init.d/qubes-input-proxy-keyboard" ] && fperms 0700 '/etc/init.d/qubes-input-proxy-keyboard'
	[ -e "${D}/etc/init.d/qubes-input-proxy-mouse" ] && fperms 0700 '/etc/init.d/qubes-input-proxy-mouse'
	[ -e "${D}/lib/modules-load.d" ] && fperms 0700 '/lib/modules-load.d'
	[ -e "${D}/lib/udev" ] && fperms 0700 '/lib/udev'
	[ -e "${D}/lib/udev/rules.d" ] && fperms 0700 '/lib/udev/rules.d'
	[ -e "${D}/lib/udev/rules.d/90-qubes-input-proxy.rules" ] && fperms 0600 '/lib/udev/rules.d/90-qubes-input-proxy.rules'
	[ -e "${D}/usr/bin/input-proxy-sender" ] && fperms 0711 '/usr/bin/input-proxy-sender'
	[ -e "${D}/usr/lib/systemd" ] && fperms 0700 '/usr/lib/systemd'
	[ -e "${D}/usr/lib/systemd/system" ] && fperms 0700 '/usr/lib/systemd/system'
	[ -e "${D}/usr/lib/systemd/system/qubes-input-sender-keyboard-mouse@.service" ] && fperms 0600 '/usr/lib/systemd/system/qubes-input-sender-keyboard-mouse@.service'
	[ -e "${D}/usr/lib/systemd/system/qubes-input-sender-keyboard@.service" ] && fperms 0600 '/usr/lib/systemd/system/qubes-input-sender-keyboard@.service'
	[ -e "${D}/usr/lib/systemd/system/qubes-input-sender-mouse@.service" ] && fperms 0600 '/usr/lib/systemd/system/qubes-input-sender-mouse@.service'
}

#pkg_postinst() {
#
#	use template && qubes_to_runlevel qubes-input-proxy-keyboard
#	use template && qubes_to_runlevel qubes-input-proxy-mouse
#}
