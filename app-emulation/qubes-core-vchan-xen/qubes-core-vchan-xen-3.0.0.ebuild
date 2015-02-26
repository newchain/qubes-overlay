# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

EGIT_REPO_URI='https://github.com/QubesOS/qubes-core-vchan-xen.git'

inherit eutils git-2

DESCRIPTION='Qubes I/O libraries'
HOMEPAGE='https://github.com/QubesOS/qubes-core-vchan-xen'

KEYWORDS=""
LICENSE='GPL-2'

if ( [ "${PV%%.*}" == 2 ] || [ "${PR}" == r200 ] ); then {

	EGIT_BRANCH='release2'
	SLOT=2
	DEPEND="!${CATEGORY}/${PN}:3"

	}; else {

	EGIT_BRANCH='master'
	SLOT=3
	DEPEND="!${CATEGORY}/${PN}:2"
};
fi

RDEPEND="app-emulation/xen-tools"
DEPEND="app-crypt/gnupg
	${DEPEND}
	${RDEPEND}"


src_prepare() {

	if [[ "${PV}" < '9999' ]]; then {

		readonly version="v${PV}"
		git checkout "${version}" 2>/dev/null

	}; else {

		readonly version="$(git tag --points-at HEAD | head 1)"
	};
	fi

	gpg --import "${FILESDIR}/qubes-developers-keys.asc" 2>/dev/null
	git verify-tag -- "${version}" || die 'Signature verification failed!'

	( [ ${SLOT} == 2 ] && [ "${PV}" != '9999' ] ) && epatch "${FILESDIR}/${PN}-2.2.9_vchan-Makefile-remove-Werror.patch"

	epatch_user
}

src_compile() {

	if [ ${SLOT} == 2 ]; then {

		emake all;

	}; else {

		cd "${S}/u2mfn"

		emake DESTDIR="${D}" all

		cd "${S}/vchan"

		emake DESTDIR="${D}" -f 'Makefile.linux' all
	};
	fi
}

src_install() {

	if [ ${SLOT} == 2 ]; then {

		emake DESTDIR="${D}" install

	}; else {

		cd "${S}/u2mfn"

		dolib 'libu2mfn.so'

		insinto '/usr/include'
		doins 'u2mfn-kernel.h'
		doins 'u2mfnlib.h'

		cd "${S}/vchan"

		dolib 'libvchan-xen.so'

		insinto '/usr/include'
		doins 'libvchan.h'

		insinto '/usr/lib/pkgconfig'
		newins 'vchan-xen.pc' 'vchan-.pc'
	};
	fi
}
