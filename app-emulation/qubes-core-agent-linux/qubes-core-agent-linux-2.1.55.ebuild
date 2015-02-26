# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-agent-linux.git'

PYTHON_COMPAT=( python2_7 )

inherit eutils git-2 python-r1 qubes user

DESCRIPTION='Qubes RPC agent for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="selinux"
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
	selinux? ( sec-policy/selinux-qubes )
	sys-apps/util-linux"


src_prepare() {

	readonly version_prefix='v'
	qubes_prepare

	if ( [ ${SLOT} == 2 ] && [ "${PV}" != '9999' ] ); then {

		epatch "${FILESDIR}/${PN}-2.1.55_misc-Makefile-remove-Werror.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qrexec-Makefile-remove-Werror.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qrexec-agent-rc.d-to-openrc.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qubes-rpc-Makefile-remove-Werror.patch"
	};
	fi

	epatch_user
}

pkg_setup() {

	# for regular users to read and place/remove files
	enewgroup 'qubes-transfer'
	# 'user' is used in template VMs and qrexec-agent operates
	# within the associated $HOME when copying files.
	enewuser 'user' -1 -1 '/home/user' 'qubes-transfer'

	chgrp qubes-transfer -- /home/user /home/user/QubesIncoming
}

src_compile() {

	emake all
}

src_install() {

	cd "${S}/qrexec"

	emake DESTDIR="${D}" install

	cd "${S}"

	emake DESTDIR="${D}" install-sysvinit

	insinto '/etc/qubes-rpc'
	doins qubes-rpc/qubes.{Filecopy,OpenInVM}

	exeinto '/usr/bin'
	exeopts '-m0755'
	doexe qubes-rpc/qvm-{copy-to-vm,move-to-vm,mru-entry,open-in-dvm,open-in-vm,run}

	$(use selinux) && doexe "${FILESDIR}/qbkdr_run"

	exeinto '/usr/lib/qubes'
	exeopts '-m0711'
	doexe qubes-rpc/{qfile-agent,qfile-unpacker,tar2qfile}

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes.conf"

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
