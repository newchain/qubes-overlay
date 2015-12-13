# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

EGIT_REPO_URI='https://github.com/QubesOS/qubes-secpack.git'

inherit eutils git-2 qubes
[[ "${PV}" < '9999' ]] && inherit versionator

DESCRIPTION='Keys, security advisories, and integrity attestations from Qubes developers.'
HOMEPAGE='https://github.com/QubesOS/qubes-secpack'

IUSE=""
KEYWORDS="~amd64"
LICENSE='GPL-2'
SLOT='0'

DEPEND="app-crypt/gnupg"
RDEPEND=""

MY_PV='marmarek_sec_45f79323'


rc_prepare() {

	readonly version_prefix=''
	qubes_prepare
}

src_compile() {

	gpg --keyid-format 0xlong --import keys/*/*.asc


	cd "${S}/canaries"

	for i in canary-*.txt; do {

		gpg --keyid-format 0xlong --verify "${i}.sig.joanna" "${i}" || die "Failed to verify authenticity of ${i}!"
		gpg --keyid-format 0xlong --verify "${i}.sig.marmarek" "${i}" || die "Failed to verify authenticity of ${i}!"
	};
	done

	cd "${S}/QSBs"

	for i in qsb-*.txt xsa-*.dot; do {

		sigext=''

		if ( [[ "${i:0:4}" == 'qsb-' ]] && [[ "${i}" > 'qsb-017' ]] && [[ "${i}" < 'qsb-019' ]] ); then {

			sigext='n';
		};
		fi

		gpg --keyid-format 0xlong --verify "${i}.sig${sigext}.joanna" "${i}" || die "Failed to verify authenticity of ${i}!"
		gpg --keyid-format 0xlong --verify "${i}.sig.marmarek" "${i}" || die "Failed to verify authenticity of ${i}!"
	};
	done


	gpg --export --output "${S}/qubes.gpg" || die 'Failed to export keyring!'
}

src_install() {

	insinto '/usr/share/qubes'
	doins 'qubes.gpg'

	insinto '/usr/share/qubes/canaries'
	doins 'canaries/'*

	for i in 'keys/'*; do {

		dodir "/usr/share/qubes/keys/${i}"

		insinto "/usr/share/qubes/keys/${i}"
		doins "${i}/"*
	};
	done;

	insinto '/usr/share/qubes/QSBs'
	doins 'QSBs/'*
}
