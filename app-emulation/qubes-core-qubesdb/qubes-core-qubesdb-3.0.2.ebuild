# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-qubesdb.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils git-r3 qubes

DESCRIPTION="Qubes configuration database"
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="template"
[ "${PV%%[_-]*}" != '9999' ] && [ "${PV%%.*}" != '4' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}"

tag_date='20150331'
qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}"

RDEPEND="${CDEPEND}"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	eapply_user


	if [ "${SLOT}" \> '0/31' ] || ( [ "${SLOT}" = '0/31' ] && [ "${PV##*.}" -gt 0 ] )
	then

	  epatch "${FILESDIR}/qubesdb-3.1.1_no-systemd.patch"

	elif [ "${SLOT}" = '0/30' ] &&  [ "${PV##*.}" -gt 2 ]
	then

	  epatch "${FILESDIR}/qubesdb-3.0.6_no-systemd.patch"

	else

	  epatch "${FILESDIR}/no-systemd.patch"

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

	fperms 0711 '/usr/bin/qubesdb-cmd'
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

	use template && qubes_to_runlevel qubesdb-daemon
}
