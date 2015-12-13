# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-agent-linux.git'

PYTHON_COMPAT=( python2_7 )

inherit eutils fcaps git-2 python-r1 qubes user

DESCRIPTION='Qubes RPC agent and utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="-dbus glib net selinux svg template"
KEYWORDS=""
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/qubes-linux-utils:${SLOT}
	app-emulation/xen-tools"

DEPEND="${CDEPEND}
	${DEPEND}
	app-crypt/gnupg
	>=app-emulation/qubes-secpack-20150603
	dbus? ( dev-python/dbus-python )"

# util-linux for logger
#
RDEPEND="${CDEPEND}
	glib?	(
		dev-python/pygobject
		svg? (
			dev-python/pycairo[svg]
			dev-python/pygobject[cairo]
		)
	)
	net? (
		sys-apps/ethtool
		sys-apps/net-tools
	)
	selinux? ( sec-policy/selinux-qubes-core[net?] )
	sys-apps/haveged
	sys-apps/util-linux"

REQUIRED_USE="
	svg? ( glib )
	template? (
			svg
			net
		)"


src_prepare() {

	readonly version_prefix='v'
	qubes_prepare


	epatch_user


	sed -i -- '1s/^/BACKEND_VMM ?= xen\n/' 'qrexec/Makefile'

	for i in misc qrexec qubes-rpc; do {

		sed -i -- 's/\ -Werror//g' "${i}/Makefile"
	};
	done

	sed -i -- 's|/sbin/ethtool|/usr/sbin/ethtool|g' 'network/setup-ip'
	sed -i -- 's|/sbin/ifconfig|/bin/ifconfig|g' 'network/setup-ip'

	sed -i -- 's|/sbin/route|/bin/route|g' 'network/setup-ip'


	exorcise_dbus() {

		epatch "${FILESDIR}/${PN}-3.0.14_exorcise-dbus.patch"
	}

	appearance_dissonance_ego_identity_reputation() {

		sed -i '/etc\/polkit-1/d' 'Makefile'
		sed -i '/qubes\.sudoers/d;/sudoers\.d_umask/d' 'Makefile'
	}


	sed -i '/var\/run/d' 'Makefile'
	sed -i 's|etc/udev|lib/udev|' 'Makefile'

	$(use dbus) || exorcise_dbus
	appearance_dissonance_ego_identity_reputation
}

pkg_setup() {

	enewgroup 'qubes'
	# 'user' is used in template VMs and qrexec-agent operates
	# within the associated $HOME when copying files.
	enewuser 'user' -1 -1 '/home/user' 'qubes'
}

src_compile() {

	emake all
}

src_install() {

	if $(use template); then {

	# rw is a mountpoint for a persistent partition. That partition
	# is what is preserved after shutdown for non-template VMs.

	# home is a bind mountpoint for rw/home.

	# mnt/removable is for a single block device attached through
	# qvm-block as xvdi.

	# home.orig/user is copied over to rw/home on an appVM's first boot.

	# MAC magic could make appVMs swallow this blue pill.

		diropts '-m0700'
		dodir 'home'
		dodir 'home.orig'

		diropts '-m0710'
		dodir 'home.orig/user'
		diropts '-m0700'
		dodir 'home.orig/user/Desktop'
		dodir 'home.orig/user/Downloads'
		diropts '-m1770'
		dodir 'home.orig/user/QubesIncoming'
		fowners user:qubes '/home.orig/user' '/home.orig/user/QubesIncoming'

	}; else {

		diropts '-m1770'
		dodir 'home/user/QubesIncoming'
		fowners user:qubes '/home/user' '/home/user/QubesIncoming'
	};
	fi


	doinitd "${FILESDIR}/qubes-core"
	doinitd "${FILESDIR}/qubes-iptables"
	doinitd "${FILESDIR}/qubes-random-seed"
	doinitd "${FILESDIR}/qubes-qrexec-agent"
	doinitd "${FILESDIR}/selinux"

	if $(use net); then {

		doinitd "${FILESDIR}/net.qubes"
	};
	fi


	emake DESTDIR="${D}" install-common

	cd "${S}/qrexec"

	emake DESTDIR="${D}" install

	cd "${S}"


	fperms 0711 '/etc/qubes-rpc/'
	fperms 0711 '/usr/lib/qubes/qfile-agent'
	fperms 0711 '/usr/lib/qubes/qfile-unpacker'
	fperms 0711 '/usr/lib/qubes/qrexec-agent'
	fperms 0700 '/usr/lib/qubes/setup-ip'
	fperms 0711 '/usr/lib/qubes/tar2qfile'

	fperms 0700 '/mnt/removable'
	fperms 0700 '/rw'


	exeinto '/usr/bin'
	$(use selinux) && doexe "${FILESDIR}/qbkdr_run"

	insopts '-m0700'
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes.conf"
	$(use template) && doins "${FILESDIR}/qubes-template.conf"

	docinto '/usr/share/doc/qubes'
	dodoc 'misc/fstab'
}

pkg_preinst() {

	if $(use template); then {

		qubes_to_runlevel 'net.qubes'
		qubes_to_runlevel 'qubes-core'
		qubes_to_runlevel 'qubes-iptables'
		qubes_to_runlevel 'qubes-random-seed'
		qubes_to_runlevel 'qubes-qrexec-agent'
		qubes_to_runlevel 'selinux'
	};
	fi
}

pkg_postinst() {

	fcaps cap_setgid,cap_setuid,cap_sys_admin,cap_sys_chroot 'usr/lib/qubes/qfile-unpacker'

	echo
	ewarn "qrexec-agent must be running before qrexec_timeout"
	ewarn "(default value = 60 seconds) is reached."
	ewarn
	ewarn "qrexec-agent requires the 'u2mfn' kernel module."
	ewarn "Either emerge qubes-kernel-module or patch the kernel"
	ewarn "manually for a static build."
	ewarn
	ewarn "Additionally, you must set 'qrexec_installed' to True"
	ewarn "for your domU to use Qubes RPC."
	echo
	einfo "Inter-VM functions are invoked through qvm-* utils."
	echo
	einfo "File copying is performed inside the 'user' user's"
	einfo "\$HOME. Look for files under /home/user/QubesIncoming".
	echo
	einfo "Add regular users to the 'qubes' group to read"
	einfo "and manipulate files there."
	echo
}
