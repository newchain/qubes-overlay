# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$


qubes_slot() {

	if ( [ "${PV%%.*}" == 2 ] || [ "${PR}" == 'r200' ] ); then {

		EGIT_BRANCH='release2'
		SLOT='0/20'
#		DEPEND="!${CATEGORY}/${PN}:3"

		};
		elif ( [ "${PV%.*}" == '3.1' ] || [ "${PR}" == 'r310' ] ); then {

		EGIT_BRANCH='release3.1'
		SLOT='0/31'
#		DEPEND="!${CATEGORY}/${PN}:2"

		};
		elif ( [ "${PV%%.*}" == '3' ] || [ "${PR}" == 'r300' ] ); then {

		EGIT_BRANCH='release3.0'
		SLOT='0/30'
#		DEPEND="!${CATEGORY}/${PN}:2"
		};
		else {

		EGIT_BRANCH='master'
		SLOT='0/40'
	};
	fi
}


qubes_prepare() {

	local version

	if [[ "${PV}" < '9999' ]]; then {

		readonly version="${version_prefix}${MY_PV:=${PV}}"
		git checkout "${version}" 2>/dev/null

	};
	else {

		readonly version="$(git tag --points-at HEAD | head -n 1)"
	};
	fi

	gpg --import "${FILESDIR}/qubes-developers-keys.asc"  2>/dev/null

	if [[ "${PV}" < '9999' ]]; then {

		git verify-tag "${version}" || die 'Signature verification failed!'

	};
	else {

		for i in $(git tag --points-at HEAD); do {

			git verify-tag "${i}" || die 'Signature verification failed!'
		};
		done;
	};
	fi
}


# This is lifted from the openrc ebuilds
#
qubes_to_runlevel() {

	if ! [[ -e "${EROOT}etc/runlevels/default/${1}" ]]; then {

		elog "Auto-adding ${1} to default runlevel..."

		ln -snf -- "/etc/init.d/${1}" "${EROOT}etc/runlevels/default/${1}"
	};
	fi
}
