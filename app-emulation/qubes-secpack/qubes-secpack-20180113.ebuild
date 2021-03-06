# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-secpack.git'

inherit git-r3 qubes

DESCRIPTION='Keys, security advisories, and integrity attestations from Qubes developers.'
HOMEPAGE='https://github.com/QubesOS/qubes-secpack'

IUSE=""
[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
LICENSE='GPL-2'
SLOT='0'

HDEPEND="${HDEPEND:-}
	app-crypt/gnupg"

MY_PV='marmarek_sec_5ddbd92b'


src_unpack() {

	if [ "${PV%%[_-]*}" != '9999' ] && [ -z "${MY_PV:-}" ]; then

		die "MY_PV must be set for specific tags"

	fi

	readonly version_prefix=''
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_compile() {

	gpg --keyid-format 0xlong --import keys/*/*.asc


	cd "${S}/canaries"

	for canary in canary-*.txt; do

		[ "${canary}" = 'canary-template.txt' ] && continue
		gpg --keyid-format 0xlong --verify "${canary}.sig.joanna" "${canary}" || die "Failed to verify authenticity of ${canary}!"
		gpg --keyid-format 0xlong --verify "${canary}.sig.marmarek" "${canary}" || die "Failed to verify authenticity of ${canary}!"

	done

	cd "${S}/QSBs"

	for advisory in qsb-*.txt xsa-*.dot; do

		sigext=''

		if [ "${advisory}" \> 'qsb-017' ] && [ "${advisory}" \< 'qsb-019' ]; then

			sigext='n'

		fi

		# bad signatures....
		if [ "${advisory}" = 'qsb-002-2012.txt' ] || [ "${advisory}" = 'qsb-023-2015.txt' ]; then

			gpg --keyid-format 0xlong --verify "${advisory}.sig${sigext}.joanna" "${advisory}" || ewarn "Failed to verify authenticity of ${advisory}!"
			continue

		fi

		gpg --keyid-format 0xlong --verify "${advisory}.sig${sigext}.joanna" "${advisory}" || die "Failed to verify authenticity of ${advisory}!"
		gpg --keyid-format 0xlong --verify "${advisory}.sig.marmarek" "${advisory}" || die "Failed to verify authenticity of ${advisory}!"

	done

	gpg --export --compress-level 9 --output "${T}/qubes_pubring.gpg" || die 'Failed to export keyring!'
	#gpg --export-ownertrust | cut -d ',' -f 1 -- - | cat -- - > "${S}/qubes_trust.txt" || die 'Failed to export ownertrust!'
}

src_install() {

	insinto '/usr/share/qubes'
	doins "${T}/qubes_pubring.gpg"
	newins "${FILESDIR}/trustdb.txt" 'qubes_trustdb.txt'
	newins "${HOME}/.gnupg/trustdb.gpg" 'qubes_trustdb.gpg'
	doins -r 'canaries'
	doins -r 'keys'
	doins -r 'QSBs'
}
