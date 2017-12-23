# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit selinux-policy-2

BASEPOL='2.20170805-r3'
MODS="${PN#selinux-}"
POLICY_FILES="${PN#selinux-}.te ${PN#selinux-}.if ${PN#selinux-}.fc"

DESCRIPTION="SELinux policy for ${PN#selinux-}"
HOMEPAGE='https://github.com/newchain'

KEYWORDS="amd64"
LICENSE='GPL-3'
SLOT='0'
