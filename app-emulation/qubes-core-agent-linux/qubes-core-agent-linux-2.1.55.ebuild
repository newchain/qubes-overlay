# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-agent-linux.git'

PYTHON_COMPAT=( python2_7 )

inherit eutils git-2 python-r1 qubes user

DESCRIPTION='Qubes RPC agent for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="glib net selinux svg template"
KEYWORDS="~amd64"
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/qubes-linux-utils:${SLOT}
	app-emulation/xen-tools"

DEPEND="${CDEPEND}
	${DEPEND}
	app-crypt/gnupg"

# util-linux for logger
#
RDEPEND="${CDEPEND}
	glib?	(
		dev-python/pygobject
		svg? (
			dev-python/pygobject[cairo]
			dev-python/pycairo[svg]
		)
	)
	net? (
		sys-apps/ethtool
		sys-apps/net-tools
	)
	selinux? ( sec-policy/selinux-qubes )
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

	if ( [ ${SLOT} == 2 ] && [ "${PV}" != '9999' ] ); then {

		epatch "${FILESDIR}/${PN}-2.1.55_qrexec-agent-rc.d-to-openrc.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qubes-core-rc.d-to-openrc-and-diet.patch"
	};
	fi

	for i in misc qrexec qubes-rpc; do {

		sed -i -- 's/\ -Werror//g' "${i}/Makefile"
	};
	done

	if $(use net); then

		sed -i -- 's|/sbin/ethtool|/usr/sbin/ethtool|g' 'network/setup-ip'
		sed -i -- 's|/sbin/ifconfig|/bin/ifconfig|g' 'network/setup-ip'
		sed -i -- 's|/sbin/route|/bin/route|g' 'network/setup-ip'
	fi

	epatch_user
}

pkg_setup() {

	# for regular users to read and place/remove files
	enewgroup 'qubes-transfer'
	# 'user' is used in template VMs and qrexec-agent operates
	# within the associated $HOME when copying files.
	enewuser 'user' -1 -1 '/home/user' 'qubes-transfer'
}

src_compile() {

	emake all
}

src_install() {

	if $(use template); then {

	# rw is a mountpoint for a volatile partition. That partition
	# is what is preserved after shutdown for non-template VMs.

	# home is a bind mountpoint for rw/home.

	# mnt/removable is for a single block device attached through
	# qvm-block as xvdi.

	# home.orig is copied over to rw/home on an appVM's first boot.

	# MAC magic could make appVMs swallow this blue pill.

		diropts '-m0700'
		dodir 'home'
		dodir 'mnt/removable'
		dodir 'rw'

		diropts '-m0755'
		dodir 'home.orig'

		diropts '-m0770'
		dodir 'home.orig/user'
		dodir 'home.orig/user/QubesIncoming'

	}; else {

		diropts '-m0770'
		dodir 'home/user/QubesIncoming'
		fowners user:qubes-transfer 'home/user' 'home/user/QubesIncoming'
	};
	fi

	cd "${S}/qrexec"

	emake DESTDIR="${D}" install

	cd "${S}"

	emake DESTDIR="${D}" install-sysvinit

	insinto '/etc/qubes-rpc'
	doins qubes-rpc/qubes.{Filecopy,OpenInVM}
	$(use glib) && doins 'qubes-rpc/qubes.GetAppmenus'

	exeinto '/usr/bin'
	exeopts '-m0755'
	$(use glib) && doexe 'misc/qubes-desktop-run'
	doexe qubes-rpc/qvm-{copy-to-vm,move-to-vm,mru-entry,open-in-dvm,open-in-vm,run}

	$(use selinux) && doexe "${FILESDIR}/qbkdr_run"

	exeinto '/usr/lib/qubes'
	exeopts '-m0755'
	$(use glib) && doexe 'misc/qubes-trigger-sync-appmenus.sh'
	exeopts '-m0711'
	doexe qubes-rpc/{qfile-agent,tar2qfile}
	exeopts '-m4711'
	doexe 'qubes-rpc/qfile-unpacker'

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes.conf"
	$(use template) && doins "${FILESDIR}/qubes-template.conf"

	if $(use net); then {

		exeinto '/usr/lib/qubes'
		exeopts '-m700'
		doexe 'network/setup-ip'

		insinto '/lib/udev/rules.d'
		doins 'network/udev-qubes-network.rules'
	};
	fi

	docinto '/usr/share/doc/qubes'
	dodoc 'misc/fstab'
}

pkg_postinst() {

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
	einfo "Add regular users to the 'qubes-transfer' group to read"
	einfo "and manipulate files there."
	echo
}
