# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-qubesdb.git'

inherit eutils git-2 qubes

DESCRIPTION="Qubes configuration database"
HOMEPAGE='https://github.com/QubesOS/qubes-core-agent-linux'

IUSE="template"
KEYWORDS="~amd64"
LICENSE='GPL-2'
SLOT='0'


CDEPEND="app-emulation/qubes-core-vchan-xen:3"

DEPEND="${CDEPEND}
	app-crypt/gnupg
	>=app-emulation/qubes-secpack-20150603"
RDEPEND="${CDEPEND}"


src_prepare() {

	readonly version_prefix='v'
	qubes_prepare


	epatch_user


	epatch "${FILESDIR}/no-systemd.patch"

	sed -i -- 's/\ -Werror//g' 'daemon/Makefile'

	sed -i -- '1s/^/BACKEND_VMM ?= xen\n/' 'client/Makefile'
	sed -i -- '1s/^/BACKEND_VMM ?= xen\n/' 'daemon/Makefile'
}

src_compile() {

	emake SYSTEMD=0 all
}

src_install() {

	emake DESTDIR="${D}" install

	newconfd "${FILESDIR}/qubesdb-daemon_conf" 'qubesdb-daemon'

	into '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubesdb.conf"
}

pkg_postinst() {

	$(use template) && qubes_to_runlevel qubesdb-daemon
}
