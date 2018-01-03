# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit selinux-policy-2

BASEPOL='2.20170805-r3'
IUSE="net"
MODS="qubes-core"
POLICY_FILES="qubes-core.te qubes-core.if qubes-core.fc"

DESCRIPTION='SELinux policy for Qubes core'
HOMEPAGE='https://github.com/newchain/qubes-policy'

KEYWORDS="amd64 x86"
LICENSE='GPL-3'
SLOT='0'