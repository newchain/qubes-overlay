# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-kernel.git'

inherit git-r3 qubes

DESCRIPTION="Linux kernel stable release keyring with 'bootstrapped' trust from Qubes tag signature"
HOMEPAGE='https://github.com/QubesOS/qubes-linux-kernel'

[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
LICENSE='GPL-2'
SLOT='0'

case "${PV:0:4}:${PR:-}" in

	4.14:*)
		EGIT_BRANCH='stable-4.14'
	;;

	4.9.:*)
		EGIT_BRANCH='stable-4.9'
	;;

	4.4.:*)
		EGIT_BRANCH='stable-4.4'
	;;

	9999:r414)
		EGIT_BRANCH='stable-4.14'
	;;

	9999:r409)
		EGIT_BRANCH='stable-4.9'
	;;

	9999)
		EGIT_BRANCH='master'
	;;

esac

[ "${PV%%[_-]*}" != '9999' ] && MY_PV="${PV/_p/-}"


tag_date='20171017'
qubes_keys_depend


src_unpack() {

	version_prefix='v'
	qubes_prepare
}

src_compile() {

	gpg --keyid-format 0xlong --no-default-keyring --keyring "${T}/keyring.gpg" --import "${S}/kernel.org-2-key.asc"
	gpg --trustdb-name "${T}/trustdb.gpg" --import-ownertrust "${FILESDIR}/trustdb.txt"

	gpg --no-default-keyring --keyring "${T}/keyring.gpg" --export --compress-level 9 --output "${T}/pubring.gpg" || die 'Failed to export keyring!'
}

src_install() {

	diropts -g portage -m 0751
	insopts -g portage -m 0644

	edirs="
		/var/lib/gentoo/gkeys
		/var/lib/gentoo/gkeys/keyrings
		/var/lib/gentoo/gkeys/keyrings/kernel
		/var/lib/gentoo/gkeys/keyrings/kernel/release"

	dodir ${edirs}

	insinto '/var/lib/gentoo/gkeys/keyrings/kernel/release'

	newins "${S}/kernel.org-2-key.asc" 'pubring.asc'
	doins "${FILESDIR}/gkey.seeds"
	doins "${T}/pubring.gpg"
	doins "${T}/trustdb.gpg"
	doins "${FILESDIR}/trustdb.txt"
}
