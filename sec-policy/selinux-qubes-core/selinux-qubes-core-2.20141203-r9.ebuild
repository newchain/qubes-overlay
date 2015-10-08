# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit selinux-policy-2

BASEPOL='2.20141203-r9'
IUSE="net"
MODS="qubes-core"
POLICY_FILES="qubes-core.te qubes-core.if qubes-core.fc"

DESCRIPTION='SELinux policy for Qubes core'
HOMEPAGE='https://github.com/2d1/qubes-policy'

KEYWORDS="~amd64"
LICENSE='GPL-3'
SLOT='0'
