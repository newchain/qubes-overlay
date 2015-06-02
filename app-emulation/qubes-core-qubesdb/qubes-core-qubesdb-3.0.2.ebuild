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
	app-crypt/gnupg"
RDEPEND="${CDEPEND}"


src_prepare() {

	readonly version_prefix='v'
	qubes_prepare


	epatch "${FILESDIR}/no-systemd.patch"

	sed -i -- 's/\ -Werror//g' 'daemon/Makefile'

	epatch_user
}

src_compile() {

	emake SYSTEMD=0 all
}

src_install() {

	emake DESTDIR="${D}" install

	into '/usr/lib/tmpfiles.d'
	doins "${FILESDIR}/qubesdb.conf"
}

pkg_postinst() {

	$(use template) && qubes_to_runlevel qubesdb-daemon
}
