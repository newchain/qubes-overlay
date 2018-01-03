# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-agent-linux.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils fcaps git-r3 python-single-r1 qubes user

DESCRIPTION='Qubes RPC agent and utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="-dbus debug +entropy glib iptables -kmod net -networkmanager python selinux svg template tinyproxy"
qubes_keywords
LICENSE='GPL-2'

qubes_slot

tag_date='20150428'
qubes_keys_depend

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/qubes-linux-utils:${SLOT}
	app-emulation/xen-tools
	${PYTHON_DEPS}"

DEPEND="${CDEPEND}
	${DEPEND}"

HDEPEND="|| (
	  sys-apps/coreutils
	  sys-apps/busybox
	)
	app-crypt/gnupg
	|| (
	  sys-apps/sed
	  sys-apps/busybox
	)"

# util-linux for logger
#
RDEPEND="${CDEPEND}
	dbus? ( dev-python/dbus-python )
	entropy? ( sys-apps/haveged )
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
	selinux? ( sec-policy/selinux-qubes-core )
	tinyproxy? ( net-proxy/tinyproxy )
	sys-apps/util-linux"

REQUIRED_USE="
	dbus? ( glib )
	glib? ( python )
	networkmanager? ( net )
	svg? ( glib )
	template? (
	  svg
	  net
	 )
	tinyproxy? ( iptables net )"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user

	use dbus || [ "${PV}" \> '3.2.22' ] || epatch "${FILESDIR}/${PN}-3.0.14_exorcise-dbus.patch"


	sed -i -e '/^PYTHON3_SITELIB/d' \
	       -e '/etc\/polkit-1/d' \
	       -e 's|etc/udev|lib/udev|' \
	       -e '/qubes\.sudoers/d' \
	       -e '/sudoers\.d_umask/d' \
	       -e '/var\/run/d' -- "${S}/Makefile"


	sed -i -e '1s/^/BACKEND_VMM ?= xen\n/' -- "${S}/qrexec/Makefile"

	for dir in misc qrexec qubes-rpc; do

	  sed -i -e 's/\ -Werror//g' -- "${S}/${dir}/Makefile"

	done

	sed -i -e 's|\(install\ qrexec-agent[^/]*/usr/\)lib|\1'"$(get_libdir)|" -- "${S}/qrexec/Makefile"

	sed -i -e 's/^python:\ python2\ python3/python: python2/g' -- "${S}/misc/Makefile"

	use glib || sed -i -e '/qubes-desktop-run/d' -- "${S}/Makefile"

	sed -i -e "s/^CFLAGS=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- "${S}/qubes-rpc/Makefile"


	# network-proxy-setup.sh
	#
	sed -i -e 's|/sbin/ethtool|/usr/sbin/ethtool|g' -- "${S}/vm-systemd/network-proxy-setup.sh"


	# qubes-firewall
	#
	cp -- "${S}/network/qubes-firewall" "${T}/qubes-firewall.old"
	cat -- "${T}/qubes-firewall.old" | tr '\n' '\v' | sed -e 's/#\ PID.*TERM//' -- - | tr '\v' '\n' > "${S}/network/qubes-firewall"
	rm -- "${T}/qubes-firewall.old"

	sed -i -e '/^PIDFILE/d' -- "${S}/network/qubes-firewall"


	# qubes-netwatcher
	#
	cp -- "${S}/network/qubes-netwatcher" "${T}/qubes-netwatcher.old"
	cat -- "${T}/qubes-netwatcher.old" | tr '\n' '\v' | sed -e 's/#\ PID.*TERM//' -- - | tr '\v' '\n' > "${S}/network/qubes-netwatcher"
	rm -- "${T}/qubes-netwatcher.old"

	sed -i -e '/^PIDFILE/d' -- "${S}/network/qubes-netwatcher" \
	       -e 's|/sbin/service qubes-firewall|/etc/init.d/qubes-firewall -D|' \
		   -e 's|\( -D start$\)|\1\;\n\t\t\t/etc/init.d/qubes-iptables -D proxy_flush;|' -- "${S}/network/qubes-netwatcher"


	# qubes-setup-dnat-to-ns
	#
	sed -i -e '/^export PATH/d' -- "${S}/network/qubes-setup-dnat-to-ns"


	if ! use tinyproxy; then

	  sed -i -e '/iptables-updates-proxy/d' \
	         -e '/tinyproxy/d' -- "${S}/Makefile"

	fi

	sed -i -e "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- "${S}/misc/Makefile"
	sed -i -e "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- "${S}/qrexec/Makefile"
	sed -i -e "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- "${S}/qubes-rpc/Makefile"

	if ! use debug; then

	  sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/misc/Makefile"
	  sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/qrexec/Makefile"
	  sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/qubes-rpc/Makefile"
	  sed -i -e 's/\((CC).*\)-g\ /\1/' -- "${S}/qubes-rpc/Makefile"

	fi


	# qubes-sysinit.sh
	#

	if ! use kmod; then

	  cp -- "${S}/vm-systemd/qubes-sysinit.sh" "${T}/qubes-sysinit.sh.old"
	  # Not needed when kernel is static and this hangs forever if something
	  # goes wrong, leaving no opportunity to inspect and fix.
	  cat -- "${T}/qubes-sysinit.sh.old"  | tr '\n' '\v' | sed -e 's:\v# Wait for \(evtchn\|xenbus\).*\(\vmkdir -p /var/run/qubes\v\):\2:' -- - | tr '\v' '\n' > "${S}/vm-systemd/qubes-sysinit.sh"
	  rm -- "${T}/qubes-sysinit.sh.old"

	fi

	cp -- "${S}/vm-systemd/qubes-sysinit.sh" "${T}/qubes-sysinit.sh.old"
	# Restricted users should not be able to touch these.
	cat -- "${T}/qubes-sysinit.sh.old"  | tr '\n' '\v' | \
	sed -e 's:\vchmod 666 /proc/xen/xenbus\v:\vchgrp qubes -- /proc/xen/xenbus\vchmod 660 /proc/xen/xenbus\v:' \
	    -e 's:\vchmod 666 /proc/u2mfn\v:\vchgrp user -- /proc/u2mfn\vchmod 060 /proc/u2mfn\v:' \
		-e 's:\vchmod 0775 /var/run/qubes\v:\vchmod 0710 /var/run/qubes\v:' \
		-e 's:\v# Set the hostname\v.*\(\v# Prepare environment\):\1:' | \
	tr '\v' '\n' > "${S}/vm-systemd/qubes-sysinit.sh"
	rm -- "${T}/qubes-sysinit.sh.old"


	# setup-ip
	#

	if ! use networkmanager || use selinux; then

	  cp -- "${S}/network/setup-ip" "${T}/setup-ip.old"
	  cat -- "${T}/setup-ip.old" | tr '\n' '\v' | sed -e 's|if \[ -f /var/run/qubes-service/network-manager.*chmod 600 \$nm_config\s*fi||' -- - | tr '\v' '\n' > "${S}/network/setup-ip"
	  rm -- "${T}/setup-ip.old"

	fi

	sed -i -e 's|/sbin/ethtool|/usr/sbin/ethtool|g' \
	       -e 's|/sbin/ifconfig|/bin/ifconfig|g' \
	       -e 's|/sbin/route|/bin/route|g' -- "${S}/network/setup-ip"


	cp -- "${FILESDIR}/qubes-"{qrexec-agent,service} "${T}"

	! use selinux && sed -i -e '/selinux/d' -- "${T}/qubes-"{qrexec-agent,service}
}

pkg_setup() {

	enewgroup 'qubes'
	enewgroup 'user'
	# 'user' is used in template VMs and qrexec-agent operates
	# within the associated $HOME when copying files.
	enewuser 'user' -1 -1 '/home/user' 'user,qubes'

	python-single-r1_pkg_setup
}

src_compile() {

	emake LIBDIR="/usr/$(get_libdir)" all
}

src_install() {

	if use template; then

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
	  diropts '-m1710'
	  dodir 'home.orig/user/QubesIncoming'
	  fowners user:qubes '/home.orig/user' '/home.orig/user/QubesIncoming'

	else

	  diropts '-m1710'
	  dodir 'home/user/QubesIncoming'
	  fowners user:qubes '/home/user' '/home/user/QubesIncoming'

	fi


	use net && doinitd "${FILESDIR}/net.qubes"
	use template && doinitd "${FILESDIR}/qubes-core"
	use iptables && doinitd "${FILESDIR}/qubes-firewall"
	use iptables && doinitd "${FILESDIR}/qubes-iptables"
	use iptables && doinitd "${FILESDIR}/qubes-netwatcher"
	use iptables && doinitd "${FILESDIR}/qubes-network"
	doinitd "${FILESDIR}/qubes-random-seed"
	doinitd "${T}/qubes-qrexec-agent"
	doinitd "${T}/qubes-service"
	use selinux && doinitd "${FILESDIR}/selinux"

	use net && dosym '/etc/init.d/net.qubes' 'etc/init.d/net.eth0'


	emake DESTDIR="${D}" LIBDIR="/usr/$(get_libdir)" install-common

	cd "${S}/qrexec"

	emake DESTDIR="${D}" LIBDIR="/usr/$(get_libdir)" install

	cd "${S}"


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
	doexe 'vm-systemd/'*'.sh'

#	fperms 0700 'etc/conf.d/'*

	for file in "${D}/etc/init.d/"*; do

		[ "${file}" = "${D}/etc/init.d/net.eth0" ] && continue
		[ -e "${file}" ] && chmod 0700 -- "${file}"

	done

	[ -e "${D}/etc/dispvm-dotfiles.tbz" ] && fperms 0600 '/etc/dispvm-dotfiles.tbz'
	[ -e "${D}/etc/qubes-rpc/" ] && fperms 0711 '/etc/qubes-rpc/'

	for file in "${D}/etc/qubes-rpc/qubes."*; do

		[ -e "${file}" ] && chmod 0755 -- "${file}"

	done

	[ -e "${D}/mnt/removable" ] && fperms 0700 '/mnt/removable'

	fperms 0711 '/rw'
	#fperms 0700 '/rw/config'

	[ -e "${D}/usr/bin/qrexec-client-vm" ] && fperms 0711 "/usr/bin/qrexec-client-vm"
	[ -e "${D}/usr/bin/qrexec-fork-server" ] && fperms 0711 "/usr/bin/qrexec-fork-server"
	[ -e "${D}/usr/bin/xenstore-watch-qubes" ] && fperms 0711 "/usr/bin/xenstore-watch-qubes"
	[ -e "${D}/usr/$(get_libdir)/qubes/close-window" ] && fperms 0711 "/usr/$(get_libdir)/qubes/close-window"
	[ -e "${D}/usr/$(get_libdir)/qubes/qfile-agent" ] && fperms 0711 "/usr/$(get_libdir)/qubes/qfile-agent"
	[ -e "${D}/usr/$(get_libdir)/qubes/qfile-unpacker" ] && fperms 0711 "/usr/$(get_libdir)/qubes/qfile-unpacker"
	[ -e "${D}/usr/$(get_libdir)/qubes/qopen-in-vm" ] && fperms 0711 "/usr/$(get_libdir)/qubes/qopen-in-vm"
	[ -e "${D}/usr/$(get_libdir)/qubes/qrexec-agent" ] && fperms 0700 "/usr/$(get_libdir)/qubes/qrexec-agent"
	[ -e "${D}/usr/$(get_libdir)/qubes/setup-ip" ] && fperms 0700 "/usr/$(get_libdir)/qubes/setup-ip"
	[ -e "${D}/usr/$(get_libdir)/qubes/tar2qfile" ] && fperms 0711 "/usr/$(get_libdir)/qubes/tar2qfile"
	[ -e "${D}/usr/$(get_libdir)/qubes/vm-file-editor" ] && fperms 0711 "/usr/$(get_libdir)/qubes/vm-file-editor"

	fperms 0700 "/usr/lib/qubes/init"
	fperms 0700 "/usr/$(get_libdir)/qubes/init"

	for file in "${D}/usr/$(get_libdir)/qubes/init/"*'.sh'; do

		[ -e "${file}" ] && chmod 0700 -- "${file}"

	done

	[ -e "${D}/usr/$(get_libdir)/qubes/init/functions" ] && fperms 0600 "/usr/$(get_libdir)/qubes/init/functions"

	[ -e "${D}/usr/sbin/qubes-firewall" ] &&  fperms 0700 '/usr/sbin/qubes-firewall'
	[ -e "${D}/usr/sbin/qubes-netwatcher" ] &&  fperms 0700 '/usr/sbin/qubes-netwatcher'

	[ -e "${D}/${PYTHON_SITEDIR}/qubes" ] && python_optimize "${D}/${PYTHON_SITEDIR}/qubes"
	python_optimize "${D}/usr/lib/qubes"
	[ -e "${D}/usr/share/nautilus-python/extensions" ] && python_optimize "${D}/usr/share/nautilus-python/extensions"
}

pkg_preinst() {

	if use template; then

	  use net && qubes_to_runlevel 'net.eth0'
	  qubes_to_runlevel 'qubes-core'
	  use iptables && qubes_to_runlevel 'qubes-firewall'
	  use iptables && qubes_to_runlevel 'qubes-iptables'
	  use iptables && qubes_to_runlevel 'qubes-netwatcher'
	  use iptables && qubes_to_runlevel 'qubes-network'
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
