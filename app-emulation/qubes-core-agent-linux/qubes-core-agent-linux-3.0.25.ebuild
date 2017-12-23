# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-agent-linux.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )
PYTHON_COMPAT=( python2_7 )

inherit eutils fcaps git-r3 python-single-r1 qubes user

DESCRIPTION='Qubes RPC agent and utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="+X11 -dbus dhcp +entropy +glib gnome gtk +iptables kde +log nautilus net -networkmanager -nm-applet +python selinux svg template -tinyproxy usb"
QUBES_RPC_NVE=( GetImageRGBA OpenURL SelectDirectory SelectFile SetDateTime SyncNtpClock )
IUSE="${IUSE} ${QUBES_RPC_NVE[@]/#/-qubes-rpc_}"
QUBES_RPC_PVE=( Backup DetachPciDevice Filecopy GetAppmenus InstallUpdatesGUI OpenInVM Restore Suspend VMShell WaitforSession )
IUSE="${IUSE} ${QUBES_RPC_PVE[@]/#/+qubes-rpc_}"
[ "${PV%%[_-]*}" != '9999' ] && [ "${PV%%.*}" != '4' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

qubes_slot

tag_date='20160229'
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

RDEPEND="${CDEPEND}
	X11? ( x11-libs/libX11 )
	entropy? ( sys-apps/haveged )
	gnome? ( gnome-extra/zenity )
	gtk? ( dev-python/pygtk )
	log? ( || (
	  sys-apps/util-linux
	  sys-apps/busybox[syslog]
	) )
	nautilus? ( dev-python/nautilus-python )
	net? (
	  dhcp? ( net-misc/dhcp )
	  iptables? ( net-firewall/iptables )
	  !networkmanager? (
	    sys-apps/ethtool
	    || (
	      sys-apps/net-tools
	      sys-apps/busybox
	    )
	  )
	  networkmanager? (
	    net-misc/networkmanager
	    || (
	      sys-apps/grep
	      sys-apps/busybox
	    )
	    || (
	      sys-apps/iproute2
	      sys-apps/busybox
	    )
	    || (
	      sys-apps/sed
	      sys-apps/busybox
	    )
	    nm-applet? (
	      gnome-extra/nm-applet
	    )
	  )
	  qubes-rpc_SyncNtpClock? ( net-misc/ntp )
	)
	python? ( "${PYTHON_DEPS}"
	  glib?	(
	    dev-python/pygobject
	    dbus? ( dev-python/dbus-python )
	    svg? (
	      dev-python/pycairo[svg]
	      dev-python/pygobject[cairo]
	    )
	  )
	)
	qubes-rpc_GetAppmenus? ( || (
	  sys-apps/findutils
	  sys-apps/busybox
	  )
	  virtual/awk
	)
	qubes-rpc_GetImageRGBA? ( dev-python/pyxdg )
	qubes-rpc_InstallUpdatesGUI? ( || (
	  sys-apps/shadow
	  sys-apps/busybox
	  )
	  app-crypt/gentoo-keys
	  app-crypt/gnupg
	  app-crypt/qubes-keys
	)
	qubes-rpc_OpenURL? ( x11-misc/xdg-utils )
	qubes-rpc_SelectDirectory? ( gnome-extra/zenity )
	qubes-rpc_SelectFile? (  gnome-extra/zenity )
	qubes-rpc_Suspend? ( || (
	  sys-apps/grep
	  sys-apps/busybox
	) )
	selinux? ( sec-policy/selinux-qubes-core )
	tinyproxy? ( net-proxy/tinyproxy )"

#todo:allow qarma in place of zenity

REQUIRED_USE="
	dbus? ( glib )
	dhcp? ( net )
	glib? ( python )
	gnome? ( python )
	iptables? ( net )
	kde? ( python )
	nautilus? ( python )
	networkmanager? ( net )
	nm-applet? ( networkmanager )
	qubes-rpc_GetImageRGBA? ( python )
	qubes-rpc_OpenURL? ( python )
	qubes-rpc_SyncNtpClock? ( net )
	svg? ( glib )
	tinyproxy? ( iptables net )
	usb? ( python )"

src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user

	use dbus || [ "${PV}" \> '3.2.22' ] || epatch "${FILESDIR}/${PN}-3.0.14_exorcise-dbus.patch"


	sed -i '/^PYTHON3_SITELIB/d' -- 'Makefile'
	sed -i '/etc\/polkit-1/d' -- 'Makefile'
	sed -i 's|etc/udev|lib/udev|' -- 'Makefile'
	sed -i '/qubes\.sudoers/d' -- 'Makefile'
	sed -i '/sudoers\.d_umask/d' -- 'Makefile'
	sed -i '/var\/run/d' -- 'Makefile'


	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- 'qrexec/Makefile'

	for dir in misc qrexec qubes-rpc
	do

	  sed -i 's/\ -Werror//g' -- "${dir}/Makefile"

	done

	sed -i 's|\(install\ qrexec-agent[^/]*/usr/\)lib|\1'"$(get_libdir)|" -- 'qrexec/Makefile'

	sed -i 's/^python:\ python2\ python3/python: python2/g' -- 'misc/Makefile' || die

	if ! use X11
	then

	  sed -i 's/^\(all:\sxenstore-watch\)\(\ python\)*\ close-window/\1\2/g' -- 'misc/Makefile'

	fi

	use dhcp || sed -i '/dhclient\.d/d' -- 'Makefile' || die
	use glib || sed -i '/qubes-desktop-run/d' -- 'Makefile' || die
	use gtk || sed -i 's/\,*qvm-mru-entry//g' -- 'Makefile' || die
	use gnome || sed -i '/-vm\.gnome/d' -- 'Makefile' || die
	use iptables || sed -i '/iptables/d' -- 'Makefile' || die
	use kde || sed -i '/-vm\.kde/d' -- 'Makefile' || die
	use kde || sed -i '/KDESERVICEDIR/d' -- 'Makefile' || die
	use nautilus || sed -i '/nautilus/d' -- 'Makefile' || die

	if use net
	then

	  sed -i 's|/sbin/ethtool|/usr/sbin/ethtool|g' -- 'network/setup-ip'
	  sed -i 's|/sbin/ifconfig|/bin/ifconfig|g' -- 'network/setup-ip'
	  sed -i 's|/sbin/route|/bin/route|g' -- 'network/setup-ip'

	  # setup-ip
	  #

	  if ! use networkmanager || use selinux
	  then

	    mv -- 'network/setup-ip' 'setup-ip.old'
	    cat 'setup-ip.old' | tr '\n' '\v' | sed -e 's|if \[ -f /var/run/qubes-service/network-manager.*chmod 600 \$nm_config\s*fi||' | tr '\v' '\n' > 'network/setup-ip'
	    rm -- 'setup-ip.old'

	  fi

	  # network-proxy-setup.sh
	  #
	  sed -i 's|/sbin/ethtool|/usr/sbin/ethtool|g' -- 'vm-systemd/network-proxy-setup.sh'


	  # qubes-firewall
	  #
	  sed -i '/^#\ PID/,/TERM/d' -- 'network/qubes-firewall'
	  sed -i '/^PIDFILE/d' -- 'network/qubes-firewall'


	  # qubes-netwatcher
	  #
	  sed -i '/^#\ PID/,/TERM/d' -- 'network/qubes-netwatcher'
	  sed -i '/^PIDFILE/d' -- 'network/qubes-netwatcher'
	  sed -i 's|/sbin/service qubes-firewall|/etc/init.d/qubes-firewall -D|' -- 'network/qubes-netwatcher'
	  sed -i 's|\( -D start$\)|\1\;\n\t\t\t/etc/init.d/qubes-iptables -D proxy_flush;|' -- 'network/qubes-netwatcher'


	  # qubes-setup-dnat-to-ns
	  #
	  sed -i '/^export PATH/d' -- 'network/qubes-setup-dnat-to-ns'

	else

	  sed -i '/qubes-setup-dnat-to-ns/d' -- 'Makefile' || die
	  sed -i '/setup-ip/d' -- 'Makefile' || die
	  sed -i '/update-proxy-configs/d' -- 'Makefile' || die
	  sed -i 's|/sbin/ethtool|/usr/sbin/ethtool|g' -- 'vm-systemd/network-proxy-setup.sh' || die

	fi

	if ! use networkmanager
	then
	
	  sed -i '/NetworkManager/d' -- 'Makefile' || die
	  sed -i '/qubes-fix-nm-conf/d' -- 'Makefile' || die

	fi

	use nm-applet || sed -i '/nm-applet/d' -- 'Makefile' || die

	if ! use python
	then

	  sed -i '/\.py$/d' -- 'Makefile' || die
	  sed -i '/\.py\s/d' -- 'Makefile' || die
	  sed -i '/\/xdg\.py/d' -- 'Makefile' || die
	  sed -i '/qrun-in-vm/d' -- 'Makefile' || die

	  sed -i 's/^\(all:\sxenstore-watch\)\ python\(\ close-window\)*/\1\2/g' -- 'misc/Makefile' || die

	fi

	use qubes-rpc_Backup || sed -i 's/Backup\,//g' -- 'Makefile'
	use qubes-rpc_Backup || use qubes-rpc_Restore ||  sed -i '/Restore/d' -- 'Makefile'
	use qubes-rpc_Backup || use qubes-rpc_Restore &&  sed -i 's/{\(Restore\)}/\1/' -- 'Makefile'
	use qubes-rpc_DetachPciDevice || sed -i '/DetachPciDevice/d' -- 'Makefile'
	use qubes-rpc_Filecopy || sed -i 's/qubes\.Filecopy\,*//g' -- 'Makefile'
	use qubes-rpc_SelectDirectory || sed -i 's/Select{File\,Directory}/Select{File}/g' -- 'Makefile'
	use qubes-rpc_SelectFile || use qubes-rpc_SelectDirectory || sed -i '/Select{File}/d' -- 'Makefile'
	use qubes-rpc_SelectFile || use qubes-rpc_SelectDirectory && sed -i 's/Select{File\\,Directory}/SelectDirectory/g' -- 'Makefile'
	use qubes-rpc_VMShell || sed -i 's/\,*qubes\.VMShell//' -- 'misc/Makefile'
	use qubes-rpc_WaitforSession || sed -i '/\.WaitForSession/d' -- 'misc/Makefile'

	if ! use qubes-rpc_GetAppmenus
	then

	  sed -i 's/\,*qubes\.GetAppmenus//g' -- 'Makefile'
	  sed -i '/qubes-trigger-sync-appmenus\.sh/d' -- 'Makefile'

	fi

	if ! use qubes-rpc_GetImageRGBA
	then

	  sed -i '/GetImageRGBA/d' -- 'Makefile'
	  sed -i '/xdg-icon/d' -- 'Makefile'

	fi

	if ! use qubes-rpc_OpenInVM
	then
	
	  sed -i 's/qubes\.OpenInVM\,*//g' -- 'Makefile'
	  sed -i 's/vm-file-editor\,*//g' -- 'Makefile'
	
	fi

	if ! use qubes-rpc_OpenURL
	then

	  sed -i '/OpenURL/d' -- 'Makefile'
	  sed -i '/qubes-open/d' -- 'Makefile'

	fi

	if ! use qubes-rpc_Suspend && ! use qubes-rpc_GetAppmenus
	then

	  sed -i '/[Ss]uspend/d' -- 'Makefile'

	elif ! use qubes-rpc_Suspend && use qubes-rpc_GetAppmenus
	then

	  sed -i 's/qubes\.SuspendPre\,qubes\.SuspendPost\,*//g' -- 'Makefile'
	  sed -i '/qubes\.SuspendP\(re\|ost\)All/d' -- 'Makefile'
	  sed -i '/suspend/d' -- 'Makefile'
	  sed -i 's/{\(qubes\.GetAppmenus\)}/\1/g' -- 'Makefile'

	fi

	if ! use qubes-rpc_SyncNtpClock
	then 
	
	  sed -i 's/\,qubes\.SyncNtpClock//g' -- 'Makefile'
	  sed -i '/sync-ntp-clock/d' -- 'Makefile'

	fi

	if use tinyproxy
	then
	
	  sed -i '/iptables-updates-proxy/d' -- 'Makefile'
	  sed -i '/tinyproxy/d' -- 'Makefile'

	fi

	sed -i "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- 'qrexec/Makefile'
	sed -i "s/^CFLAGS+\?=\(.*\)$/CFLAGS=\1 ${CFLAGS}/g" -- 'qubes-rpc/Makefile'


	# qubes-sysinit.sh
	#
	mv -- 'vm-systemd/qubes-sysinit.sh' 'qubes-sysinit.sh.old'
	cat -- 'qubes-sysinit.sh.old'  | tr '\n' '\v' | sed -e 's|\vsystemd.*u2mfn\v||;s|\v# Set\ the\ hostname.*\vexit 0\v|\vexit 0\v|' | tr '\v' '\n' > 'vm-systemd/qubes-sysinit.sh'
	rm -- 'qubes-sysinit.sh.old'

	sed -i '/^PROTECTED_/d' -- 'vm-systemd/qubes-sysinit.sh'
	sed -i '/^# Location /d' -- 'vm-systemd/qubes-sysinit.sh'
}


pkg_setup() {

	enewgroup 'qubes'
	# 'user' is used in template VMs and qrexec-agent operates
	# within the associated $HOME when copying files.
	enewuser 'user' -1 -1 '/home/user' 'qubes'

	python-single-r1_pkg_setup
}

src_compile() {

	emake LIBDIR="/usr/$(get_libdir)" all
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
	  diropts '-m1710'
	  dodir 'home.orig/user/QubesIncoming'
	  fowners user:qubes '/home.orig/user' '/home.orig/user/QubesIncoming'

	else

	  diropts '-m1710'
	  dodir 'home/user/QubesIncoming'
	  fowners user:qubes '/home/user' '/home/user/QubesIncoming'

	fi


	use net && doinitd "${FILESDIR}/net.qubes"
	doinitd "${FILESDIR}/qubes-core"
	use iptables && doinitd "${FILESDIR}/qubes-firewall"
	use iptables && doinitd "${FILESDIR}/qubes-iptables"
	use iptables && doinitd "${FILESDIR}/qubes-netwatcher"
	use iptables && doinitd "${FILESDIR}/qubes-network"
	doinitd "${FILESDIR}/qubes-random-seed"
	doinitd "${FILESDIR}/qubes-qrexec-agent"
	doinitd "${FILESDIR}/qubes-service"
	use selinux && doinitd "${FILESDIR}/selinux"

	fperms 0700 '/etc/init.d/'{net.qubes,qubes-core,qubes-firewall,qubes-iptables,qubes-netwatcher,qubes-network,qubes-random-seed,qubes-qrexec-agent,qubes-service,selinux}

	use net && dosym '/etc/init.d/net.qubes' 'etc/init.d/net.eth0'


	emake DESTDIR="${D}" LIBDIR="/usr/$(get_libdir)" install-common
	emake DESTDIR="${D}" LIBDIR="/usr/$(get_libdir)" install-init

	cd "${S}/qrexec"

	emake DESTDIR="${D}" LIBDIR="/usr$(get_libdir)" install

	cd "${S}"


	#fperms 0600 '/etc/dispvm-dotfiles.tbz'
	fperms 0711 '/etc/qubes-rpc/'
	fperms 0711 '/usr/bin/qrexec-client-vm'
	fperms 0711 "/usr/$(get_libdir)/qubes/qfile-agent"
	fperms 0711 "/usr/$(get_libdir)/qubes/qfile-unpacker"
	fperms 0700 "/usr/$(get_libdir)/qubes/qrexec-agent"
	use net && fperms 0700 "/usr/$(get_libdir)/qubes/setup-ip"
	fperms 0711 "/usr/$(get_libdir)/qubes/tar2qfile"

	use iptables && fperms 0700 '/usr/sbin/qubes-firewall'
	use iptables && fperms 0700 '/usr/sbin/qubes-netwatcher'

	fperms 0700 '/mnt/removable'
	fperms 0700 '/rw'
	#fperms 0700 '/rw/config'


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

	[ -e "${D}/${PYTHON_SITEDIR}/qubes" ] && python_optimize "${D}/${PYTHON_SITEDIR}/qubes"
	python_optimize "${D}/usr/lib/qubes"
	[ -e "${D}/usr/share/nautilus-python/extensions" ] && python_optimize "${D}/usr/share/nautilus-python/extensions"
}

pkg_preinst() {

	if use template
	then

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
