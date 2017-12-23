# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit selinux-policy-2

BASEPOL='2.20170805-r3'
MODS="qubes-gui"
POLICY_FILES="qubes-gui.te qubes-gui.if qubes-gui.fc"

DESCRIPTION='SELinux policy for Qubes GUI'
HOMEPAGE='https://github.com/newchain/qubes-policy'

IUSE="pulseaudio"
KEYWORDS="~amd64"
LICENSE='GPL-3'
SLOT='0'

DEPEND="sec-policy/selinux-qubes-core"
RDEPEND="sec-policy/selinux-qubes-core"
