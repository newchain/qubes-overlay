# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-qubesdb.git'

#MULTILIB_COMPAT=( abi_x86_{32,64} )

inherit eutils git-r3 qubes

DESCRIPTION="Qubes configuration database"
HOMEPAGE='https://github.com/QubesOS/qubes-core-qubesdb'

IUSE="-debug python template"
qubes_keywords
LICENSE='GPL-2'

qubes_slot

CDEPEND="app-emulation/qubes-core-vchan-xen:${SLOT}"

tag_date='20160107'
qubes_keys_depend

DEPEND="${CDEPEND}
	${DEPEND}"

HDEPEND="${HDEPEND}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND}"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user


	if [ "${SLOT}" \> '0/31' ] || ( [ "${SLOT}" = '0/31' ] && [ "${PV##*.}" -gt 0 ] ); then

		epatch "${FILESDIR}/qubesdb-3.1.1_no-systemd.patch"

	elif [ "${SLOT}" = '0/30' ] && [ "${PV##*.}" -gt 2 ]; then

		epatch "${FILESDIR}/qubesdb-3.0.6_no-systemd.patch"

	else

		epatch "${FILESDIR}/no-systemd.patch"

	fi

	sed -i -e "1s/^CFLAGS\(\ \?+\?=\ \?.*\)$/CFLAGS\1 ${CFLAGS}/" -- "${S}/client/Makefile"
	sed -i -e "8s/^CFLAGS\(\ \?+\?=\ \?.*\)$/CFLAGS\1 ${CFLAGS}/" -- "${S}/daemon/Makefile"

	sed -i -e 's/\ -Werror//g' -- "${S}/client/Makefile"
	sed -i -e 's/\ -Werror//g' -- "${S}/daemon/Makefile"

	sed -i -e '1s/^/BACKEND_VMM ?= xen\n/' -- "${S}/client/Makefile"
	sed -i -e '1s/^/BACKEND_VMM ?= xen\n/' -- "${S}/daemon/Makefile"

	if ! use debug; then

		sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/client/Makefile"
		sed -i -e 's/\(CFLAGS.*\)-g\ /\1/' -- "${S}/daemon/Makefile"

	fi

	use python || sed -i -e '/python/d' -- "${S}/Makefile"
}

src_compile() {

	emake SYSTEMD=0 all
}

src_install() {

	emake DESTDIR="${D}" install

	newinitd "${FILESDIR}/qubesdb-daemon_initd" 'qubesdb-daemon'
	newconfd "${FILESDIR}/qubesdb-daemon_confd" 'qubesdb-daemon'

	insopts '-m0600'
	insinto '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubesdb.conf"

	[ -e "${D}/etc/conf.d" ] && fperms 0700 '/etc/conf.d'
	[ -e "${D}/etc/conf.d/qubesdb-daemon" ] && fperms 0600 '/etc/conf.d/qubesdb-daemon'
	[ -e "${D}/etc/init.d" ] && fperms 0700 '/etc/init.d'
	[ -e "${D}/etc/init.d/qubesdb-daemon" ] && fperms 0700 '/etc/init.d/qubesdb-daemon'

	[ -e "${D}/usr/bin/qubesdb-cmd" ] && fperms 0711 '/usr/bin/qubesdb-cmd'
	[ -e "${D}/usr/sbin/qubesdb-daemon" ] && fperms 0700 '/usr/sbin/qubesdb-daemon'
	[ -e "${D}/usr/lib/tmpfiles.d" ] && fperms 0700 '/usr/lib/tmpfiles.d'
}

pkg_postinst() {

	use template && qubes_to_runlevel qubesdb-daemon
}
