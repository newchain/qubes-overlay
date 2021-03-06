# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit selinux-policy-2

BASEPOL="${PF}"
MODS="${PN#selinux-}"
POLICY_FILES="${PN#selinux-}.te ${PN#selinux-}.if ${PN#selinux-}.fc"

DESCRIPTION='SELinux policy for Qubes split GPG'
HOMEPAGE='https://github.com/newchain/qubes-policy'

KEYWORDS="amd64 x86"
LICENSE='GPL-3'
SLOT='0'

DEPEND="sec-policy/selinux-qubes-core"
RDEPEND="${DEPEND}"
