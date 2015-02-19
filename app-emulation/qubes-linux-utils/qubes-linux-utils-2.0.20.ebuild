# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-utils.git'

PYTHON_COMPAT=( python2_7 )

inherit eutils git-2 python-r1

DESCRIPTION='Qubes utilities for Linux VMs'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-utils'

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
	app-emulation/xen-tools"
DEPEND="app-crypt/gnupg
	${DEPEND}
	${RDEPEND}"


src_prepare() {

	if [[ "${PV}" < '9999' ]]; then {

		readonly version="v${PV}"
		git checkout "${version}" 2>/dev/null

	} else {

		readonly version="$(git tag --points-at HEAD | head -n 1)"
	};
	fi

	gpg --import "${FILESDIR}/qubes-developers-keys.asc" 2>/dev/null
	git verify-tag "${version}" || die 'Signature verification failed!'

	if ( [ ${SLOT} == 2 ] && [ "${PV}" != '9999' ] ); then {

		epatch "${FILESDIR}/${PN}-2.0.20_qmemman-Makefile-remove-Werror.patch"
		epatch "${FILESDIR}/${PN}-2.0.20_qrexec-lib-Makefile-remove-Werror.patch"
		epatch "${FILESDIR}/${PN}-2.0.20_udev-Makefile-paths.patch"
	};
	fi

	epatch_user
}

src_compile() {

	emake all
}

src_install() {

	emake DESTDIR="${D}" install
}
