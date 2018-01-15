# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit selinux-policy-2

BASEPOL="${PF}"
MODS="${PN#selinux-}"
#POLICY_FILES="${PN#selinux-}-${PVR}.cil"
POLICY_FILES="${PN#selinux-}.cil"

DESCRIPTION="SELinux policy for ${PN#selinux-}"
HOMEPAGE='https://github.com/newchain/polsec'

KEYWORDS="amd64 x86"
LICENSE='GPL-3'
SLOT='0'
