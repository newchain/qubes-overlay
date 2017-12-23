# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-kernel.git'
# 3.12 is the latest published branch, master doesn't exist.
EGIT_BRANCH='stable-3.12'

# Unfortunately, the module compiles within the kernel tree.
# This means that the portage sandbox must be disabled
# (FEATURES=-sandbox) You may wish to clone your Gentoo HVM before
# doing so, and compare the two afterward.
#
# qubes-sources with u2mfn patched in would be easier, but inefficient.
#BUILD_PARAMS="-C /lib/modules/$(uname -r)/build/ SUBDIRS=u2mfn"
BUILD_PARAMS="-C /lib/modules/3.2.96/build/ SUBDIRS=u2mfn"
BUILD_TARGETS='modules'
MODULE_NAMES="u2mfn(extra:${S}/u2mfn:/usr/src/linux/u2mfn)"

inherit eutils git-r3 linux-mod qubes

DESCRIPTION='Qubes u2mfn module for Linux kernels'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-kernel'

KEYWORDS="~amd64"
LICENSE='GPL-2'
SLOT='0'

qubes_keys_depend

DEPEND="${DEPEND}
	app-emulation/qubes-core-vchan-xen
	sys-kernel/hardened-sources"


src_unpack() {

	readonly version_prefix='R'
	qubes_prepare
}

pkg_setup() {

	linux-mod_pkg_setup
}

src_prepare() {

	epatch_user
}

src_compile() {

	linux-mod_src_compile
}

pkg_preinst() {

	linux-mod_preinst
}

src_install() {

	linux-mod_src_install
}

pkg_postinst() {

	linux-mod_postinst

	echo
	ewarn 'Unfortunately, without patching the kernel tree, u2mfn cannot'
	ewarn 'be used with a static kernel. Be sure to clean your kernel tree'
	ewarn 'after emerging this package.'
	echo
}

pkg_postrm() {

	linux-mod_postrm
}
