# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4

inherit selinux-policy-2

BASEPOL='2.20141203-r3'
MODS="qubes-core-agent qubes-gui-agent"
POLICY_FILES="qubes-core-agent.te qubes-core-agent.if qubes-core-agent.fc qubes-gui-agent.te qubes-gui-agent.if qubes-gui-agent.fc"

DESCRIPTION='SELinux policy for Qubes'
HOMEPAGE='https://github.com/2d1/qubes-policy'

KEYWORDS="~amd64"
LICENSE='GPL-3'
SLOT='0'
