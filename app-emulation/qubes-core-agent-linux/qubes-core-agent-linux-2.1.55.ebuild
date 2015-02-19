# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-agent-linux.git'

PYTHON_COMPAT=( python2_7 )

inherit eutils git-2 python-r1

DESCRIPTION='Qubes RPC agent for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

KEYWORDS="~amd64"
LICENSE='GPL-2'

if ( [ "${PV%%.*}" == 2 ] || [ "${PR}" == 'r200' ] ); then {

	EGIT_BRANCH='release2'
	SLOT=2
	DEPEND="!${CATEGORY}/${PN}:3"

	}; else {

	EGIT_BRANCH='master'
	SLOT=3
	DEPEND="!${CATEGORY}/${PN}:2"
};
fi

RDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}
	app-emulation/qubes-linux-utils:${SLOT}
	app-emulation/xen-tools"

DEPEND="${DEPEND}
	${RDEPEND}
	app-crypt/gnupg"


src_prepare() {

	if [[ "${PV}" < '9999' ]]; then {

		readonly version="v${PV}"
		git checkout "${version}" 2>/dev/null

	}; else {

		readonly version="$(git tag --points-at HEAD | head -n 1)"
	};
	fi

	gpg --import "${FILESDIR}/qubes-developers-keys.asc" 2>/dev/null
	git verify-tag "${version}" || die 'Signature verification failed!'

	if ( [ ${SLOT} == 2 ] && [ "${PV}" != '9999' ] ); then {

		epatch "${FILESDIR}/${PN}-2.1.55_qrexec-Makefile-remove-Werror.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qrexec-agent-rc.d-to-openrc.patch"
		epatch "${FILESDIR}/${PN}-2.1.55_qubes-rpc-Makefile-remove-Werror.patch"
	};
	fi

	epatch_user
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
	exeopts '-m0711'
	doexe qubes-rpc/qvm-{copy-to-vm,move-to-vm,mru-entry,open-in-dvm,open-in-vm,run}

	exeinto '/usr/lib/qubes'
	exeopts '-m0700'
	doexe qubes-rpc/{qfile-agent,qfile-unpacker,tar2qfile}

	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubes.conf"

}
