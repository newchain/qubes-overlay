# Copyright 2014-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="6"

DESCRIPTION="A OpenPGP/GPG keyring of Qubes developers GPG keys"
HOMEPAGE="https://wiki.gentoo.org/wiki/Project:Gentoo-keys"

LICENSE="GPL-3"
SLOT="0"

[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

DEPEND="=app-emulation/qubes-secpack-${PV}"

S="${WORKDIR}"


src_install() {

	insinto '/var/lib/gentoo/gkeys/keyrings'
	doins -r "${FILESDIR}/qubes"

	insinto '/var/lib/gentoo/gkeys/keyrings/qubes/release'
	newins '/usr/share/qubes/qubes_pubring.gpg' 'pubring.gpg'
	newins '/usr/share/qubes/qubes_trustdb.gpg' 'trustdb.gpg'
	newins '/usr/share/qubes/qubes_trustdb.txt' 'trustdb.txt'
}
