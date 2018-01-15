# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-gui-agent-xen-hvm-stubdom.git'

inherit git-r3 qubes

DESCRIPTION='Fetch Qubes GUI stubdom sources for xen-tools-patches'
HOMEPAGE='https://github.com/QubesOS/qubes-gui-agent-xen-hvm-stubdom'

KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

qubes_keys_depend

DEPEND="${CDEPEND:-}
	${DEPEND:-}"

RDEPEND="${CDEPEND:-}"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user
}

src_compile() {

	true
}

src_install() {

	true
}
