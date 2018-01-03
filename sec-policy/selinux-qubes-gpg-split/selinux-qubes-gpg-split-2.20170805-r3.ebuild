# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit selinux-policy-2

BASEPOL='2.20170805-r3'
MODS="qubes-gpg-split"
POLICY_FILES="qubes-gpg-split.te qubes-gpg-split.if qubes-gpg-split.fc"

DESCRIPTION='SELinux policy for Qubes split GPG'
HOMEPAGE='https://github.com/newchain/qubes-policy'

KEYWORDS="amd64 x86"
LICENSE='GPL-3'
SLOT='0'

DEPEND="sec-policy/selinux-qubes-core"
RDEPEND="${DEPEND}"
