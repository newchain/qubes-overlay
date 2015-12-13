# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit selinux-policy-2

BASEPOL='2.20141203-r10'
MODS="qubes-gui"
POLICY_FILES="qubes-gui.te qubes-gui.if qubes-gui.fc"

DESCRIPTION='SELinux policy for Qubes GUI'
HOMEPAGE='https://github.com/loveithateit/qubes-policy'

IUSE="pulseaudio"
KEYWORDS="~amd64"
LICENSE='GPL-3'
SLOT='0'

DEPEND="sec-policy/selinux-qubes-core"
RDEPEND="sec-policy/selinux-qubes-core"
