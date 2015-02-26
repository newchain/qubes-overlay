# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $


qubes_slot() {

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
}


qubes_prepare() {

	if [[ "${PV}" < '9999' ]]; then {

		readonly version="${version_prefix}${PV}"
		git checkout "${version}" 2>/dev/null

	}; else {

		readonly version="$(git tag --points-at HEAD | head -n 1)"
	};
	fi

	gpg --import "${FILESDIR}/qubes-developers-keys.asc" 2>/dev/null
	git verify-tag "${version}" || die 'Signature verification failed!'
}
