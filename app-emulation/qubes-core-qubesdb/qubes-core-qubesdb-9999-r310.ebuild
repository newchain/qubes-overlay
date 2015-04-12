# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-qubesdb.git'

inherit eutils git-2 qubes

DESCRIPTION="Qubes configuration database"
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="template"
KEYWORDS=""
LICENSE='GPL-2'

qubes_slot


CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}"

DEPEND="${CDEPEND}
	app-crypt/gnupg
	>=app-emulation/qubes-secpack-20150603"
RDEPEND="${CDEPEND}"


src_prepare() {

	readonly version_prefix='v'
	qubes_prepare


	epatch_user


	if [[ "${SLOT}" > '0/31' ]] || ( [ "${SLOT}" == '0/31' ] && [ "${PV##*.}" -gt 0 ] ); then {

		epatch "${FILESDIR}/qubesdb-3.1.1_no-systemd.patch"
	};
	elif [ "${SLOT}" == '0/30' ] &&  [ "${PV##*.}" -gt 2 ]; then {

		epatch "${FILESDIR}/qubesdb-3.0.3_no-systemd.patch"
	};
	else {
		epatch "${FILESDIR}/no-systemd.patch"
	};
	fi

	sed -i 's/\ -Werror//g' -- 'daemon/Makefile'

	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- 'client/Makefile'
	sed -i '1s/^/BACKEND_VMM ?= xen\n/' -- 'daemon/Makefile'
}

src_compile() {

	emake SYSTEMD=0 all
}

src_install() {

	emake DESTDIR="${D}" install

	fperms 0700 '/usr/sbin/qubesdb-daemon'

	doinitd "${FILESDIR}/qubesdb-daemon"
	newconfd "${FILESDIR}/qubesdb-daemon_conf" 'qubesdb-daemon'
	fperms 0600 '/etc/conf.d/qubesdb-daemon'
	fperms 0700 '/etc/init.d/qubesdb-daemon'

	insopts '-m0600'
	into '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubesdb.conf"
}

pkg_postinst() {

	$(use template) && qubes_to_runlevel qubesdb-daemon
}
