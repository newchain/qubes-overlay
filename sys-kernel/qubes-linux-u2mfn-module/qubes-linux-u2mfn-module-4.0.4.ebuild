# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-utils.git'
EGIT_BRANCH='master'

# Unfortunately, the module compiles within the kernel tree.
# This means that the portage sandbox must be disabled
# (FEATURES=-sandbox) You may wish to clone your Gentoo VM before
# doing so, and compare the two afterward.
BUILD_PARAMS="-C /lib/modules/${KV_FULL}/build/ SUBDIRS=u2mfn"
BUILD_TARGETS='modules'
MODULE_NAMES="u2mfn(extra:${S}/kernel-modules/u2mfn:${S})"

inherit git-r3 linux-mod qubes

DESCRIPTION='Qubes u2mfn module for Linux kernels'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-utils'

KEYWORDS="~amd64 ~x86"
LICENSE='GPL-2'
SLOT='0'

tag_date='20180112'
qubes_keys_depend

DEPEND="${DEPEND:-}
	app-emulation/qubes-core-vchan-xen"


src_unpack() {

	readonly version_prefix='R'
	qubes_prepare
}

pkg_setup() {

	linux-mod_pkg_setup
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
	ewarn 'Be sure to clean your kernel tree after emerging this package.'
	echo
	ewarn 'Try sys-kernel/qubes-linux-u2mfn-patch instead for a static build.'
	echo
}

pkg_postrm() {

	linux-mod_postrm
}
