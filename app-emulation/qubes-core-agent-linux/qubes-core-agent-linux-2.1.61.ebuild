# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-agent-linux.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils fcaps git-r3 python-single-r1 qubes user

DESCRIPTION='Qubes RPC agent and utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="-dbus glib net -networkmanager selinux svg template"
[ "${PV%%[_-]*}" != '9999' ] && [ "${PV%%.*}" != '4' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

qubes_slot

tag_date='20150428'
qubes_keys_depend

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/qubes-linux-utils:${SLOT}
	app-emulation/xen-tools"

DEPEND="${CDEPEND}
	${DEPEND}
	dbus? ( dev-python/dbus-python )"

# util-linux for logger
#
RDEPEND="${CDEPEND}
	glib?	(
	  dev-python/pygobject
	  svg? (
	    dev-python/pycairo[svg(+)]
	    dev-python/pygobject[cairo(+)]
	  )
	)
	net? (
	  sys-apps/ethtool
	  sys-apps/net-tools
	)
	networkmanager? ( net-misc/networkmanager )
	selinux? ( sec-policy/selinux-qubes-core[net?] )
	sys-apps/haveged
	sys-apps/util-linux"

REQUIRED_USE="
	svg? ( glib )
	template? (
	  svg
	  net
	 )"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user


	use dbus || epatch "${FILESDIR}/${PN}-3.0.14_exorcise-dbus.patch"


	sed -i '/^PYTHON3_SITELIB/d' -- 'Makefile'
	sed -i '/etc\/polkit-1/d' -- 'Makefile'
	sed -i 's|etc/udev|lib/udev|' -- 'Makefile'
	sed -i '/qubes\.sudoers/d;/sudoers\.d_umask/d' -- 'Makefile'
	sed -i '/var\/run/d' -- 'Makefile'


	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- 'qrexec/Makefile'

	for dir in misc qrexec qubes-rpc
	do

	  sed -i 's/\ -Werror//g' -- "${dir}/Makefile"

	done

	sed -i 's/^python:\ python2\ python3/python: python2/g' -- 'misc/Makefile'

	sed -i "s/^CFLAGS=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- 'qubes-rpc/Makefile'


	# network-proxy-setup.sh
	#

	sed -i 's|/sbin/ethtool|/usr/sbin/ethtool|g' -- 'vm-systemd/network-proxy-setup.sh'


	# qubes-firewall
	#

	mv -- 'network/qubes-firewall' 'qubes-firewall.old'
	cat -- 'qubes-firewall.old' | tr '\n' '\v' | sed -e 's/#\ PID.*TERM//' -- - | tr '\v' '\n' > 'network/qubes-firewall'

	sed -i '/^PIDFILE/d' -- 'network/qubes-firewall'
	sed -i 's/qubesdb-write $XENSTORE_ERROR/qubesdb-write "$XENSTORE_ERROR"/' -- 'network/qubes-firewall'


	# qubes-netwatcher
	#
	mv -- 'network/qubes-netwatcher' 'qubes-netwatcher.old'
	cat -- 'qubes-netwatcher.old' | tr '\n' '\v' | sed -e 's/#\ PID.*TERM//' -- - | tr '\v' '\n' > 'network/qubes-netwatcher'
	rm -- 'qubes-netwatcher.old'

	sed -i '/^PIDFILE/d' -- 'network/qubes-netwatcher'

	sed -i 's|/sbin/service qubes-firewall|/etc/init.d/qubes-firewall -D|' -- 'network/qubes-netwatcher'
	sed -i 's|\( -D start$\)|\1\;\n\t\t\t/etc/init.d/qubes-iptables -D stop;\n\t\t\t/etc/init.d/qubes-iptables -D start;|' -- 'network/qubes-netwatcher'


	# qubes-setup-dnat-to-ns
	#
	sed -i '/^export PATH/d' -- 'network/qubes-setup-dnat-to-ns'


	# qubes-sysinit.sh
	#

	mv -- 'vm-systemd/qubes-sysinit.sh' 'qubes-sysinit.sh.old'
	cat -- 'qubes-sysinit.sh.old'  | tr '\n' '\v' | sed -e 's|\vsystemd.*u2mfn\v||;s|\v# Set\ the\ hostname.*\vexit 0\v|\vexit 0\v|' -- - | tr '\v' '\n' > 'vm-systemd/qubes-sysinit.sh'
	rm -- 'qubes-sysinit.sh.old'

	sed -i '/^PROTECTED_/d' -- 'vm-systemd/qubes-sysinit.sh'
	sed -i '/^# Location /d' -- 'vm-systemd/qubes-sysinit.sh'


	# setup-ip
	#

	if ! use net || use selinux
	then

	  mv -- 'network/setup-ip' 'setup-ip.old'
	  cat -- 'setup-ip.old' | tr '\n' '\v' | sed -e 's|if \[ -f /var/run/qubes-service/network-manager.*chmod 600 \$nm_config\s*fi||' -- - | tr '\v' '\n' > 'network/setup-ip'
	  rm -- 'setup-ip.old'

	fi

	sed -i 's|/sbin/ethtool|/usr/sbin/ethtool|g' -- 'network/setup-ip'
	sed -i 's|/sbin/ifconfig|/bin/ifconfig|g' -- 'network/setup-ip'
	sed -i 's|/sbin/route|/bin/route|g' -- 'network/setup-ip'

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

	if use template
	then

	# rw is a mountpoint for a persistent partition. That partition
	# is what is preserved after shutdown for non-template VMs.

	# home is a bind mountpoint for rw/home.

	# mnt/removable is for a single block device attached through
	# qvm-block as xvdi.

	# home.orig/user is copied over to rw/home on an appVM's first boot.

	# grsec MAC magic (h object mode) makes appVMs swallow this blue pill.

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

	else

	  diropts '-m1770'
	  dodir 'home/user/QubesIncoming'
	  fowners user:qubes '/home/user' '/home/user/QubesIncoming'

	fi


	doinitd "${FILESDIR}/net.qubes"
	doinitd "${FILESDIR}/qubes-core"
	doinitd "${FILESDIR}/qubes-firewall"
	doinitd "${FILESDIR}/qubes-iptables"
	doinitd "${FILESDIR}/qubes-netwatcher"
	doinitd "${FILESDIR}/qubes-network"
	doinitd "${FILESDIR}/qubes-random-seed"
	doinitd "${FILESDIR}/qubes-qrexec-agent"
	doinitd "${FILESDIR}/qubes-service"
	doinitd "${FILESDIR}/selinux"

	fperms 0700 '/etc/init.d/'{net.qubes,qubes-core,qubes-firewall,qubes-iptables,qubes-netwatcher,qubes-network,qubes-random-seed,qubes-qrexec-agent,qubes-service,selinux}
#	fperms 0700 'etc/conf.d/'*

	dosym '/etc/init.d/net.qubes' 'etc/init.d/net.eth0'


	emake DESTDIR="${D}" install-common

	cd "${S}/qrexec"

	emake DESTDIR="${D}" install

	cd "${S}"


	fperms 0711 '/etc/qubes-rpc/'
	fperms 0711 '/usr/lib/qubes/qfile-agent'
	fperms 0711 '/usr/lib/qubes/qfile-unpacker'
	fperms 0700 '/usr/lib/qubes/qrexec-agent'
	fperms 0700 '/usr/lib/qubes/setup-ip'
	fperms 0711 '/usr/lib/qubes/tar2qfile'

	fperms 0700 '/usr/sbin/qubes-firewall'
	fperms 0700 '/usr/sbin/qubes-netwatcher'

	fperms 0700 '/mnt/removable'
	fperms 0700 '/rw'
#	fperms 0700 '/rw/config'


	exeinto '/usr/bin'
	use selinux && doexe "${FILESDIR}/qbkdr_run"

	insopts '-m0600'
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes.conf"
	use template && doins "${FILESDIR}/qubes-template.conf"

	docinto '/usr/share/doc/qubes'
	dodoc 'misc/fstab'

	exeopts '-m0700'
	exeinto '/usr/lib/qubes/init'
	doexe 'vm-systemd/'*.sh
#	doexe "${FILESDIR}/qubes-sysinit.sh"
}

pkg_preinst() {

	if use template
	then

	  qubes_to_runlevel 'net.eth0'
	  qubes_to_runlevel 'qubes-core'
	  qubes_to_runlevel 'qubes-firewall'
	  qubes_to_runlevel 'qubes-iptables'
	  qubes_to_runlevel 'qubes-netwatcher'
	  qubes_to_runlevel 'qubes-network'
	  qubes_to_runlevel 'qubes-random-seed'
	  qubes_to_runlevel 'qubes-qrexec-agent'
	  use selinux && qubes_to_runlevel 'selinux'

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
