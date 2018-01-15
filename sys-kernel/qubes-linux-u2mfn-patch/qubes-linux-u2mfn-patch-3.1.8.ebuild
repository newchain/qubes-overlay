# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-utils.git'

inherit git-r3 qubes

DESCRIPTION='u2mfn kernel patch for Qubes GUI'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-utils'

IUSE=""

qubes_keywords
LICENSE='GPL-2'

qubes_slot

CDEPEND="${CDEPEND:-}"

tag_date='20160208'
qubes_keys_depend

DEPEND="${CDEPEND:-}
	${DEPEND:-}"

HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/diffutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"


src_unpack() {

	version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_prepare() {

	eapply_user

	cat -- "${FILESDIR}/drivers.Makefile.patch" > "${T}/u2mfn.patch"
	diff -u -- '/dev/null' "${S}/kernel-modules/u2mfn/Makefile" | sed -e '1s/\s*[0-9]\{4\}.*$//' -e '2s:\s.*$: b/drivers/u2mfn/Makefile:' -e 's/^+obj-m/+obj-y/' -- - | cat -- >> "${T}/u2mfn.patch"
	diff -u -- '/dev/null' "${S}/kernel-modules/u2mfn/u2mfn.c" | sed -e '1s/\s*[0-9]\{4\}.*$//' -e '2s:\s.*$: b/drivers/u2mfn/u2mfn.c:' -- - | cat -- >> "${T}/u2mfn.patch"
}

src_compile() {

	true
}

src_install() {

	diropts -g portage -m 0750
	insopts -g portage -m 0640

	edirs="
		/etc/portage
		/etc/portage/patches
		/etc/portage/patches/sys-kernel
		/etc/portage/patches/sys-kernel/vanilla-sources"

	dodir ${edirs}

	insinto '/etc/portage/patches/sys-kernel/vanilla-sources'
	doins "${T}/u2mfn.patch"
}
