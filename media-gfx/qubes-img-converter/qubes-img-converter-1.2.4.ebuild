# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-app-linux-img-converter.git'

PYTHON_COMPAT=( python2_7 )

inherit git-r3 python-single-r1 qubes

DESCRIPTION='Qrexec image converter for Qubes'
HOMEPAGE='https://github.com/QubesOS/qubes-app-linux-img-converter'

IUSE="gnome nautilus svg zenity xdg-icon"
qubes_keywords
LICENSE='GPL-2'

SLOT='0'

tag_date='20171223'
qubes_keys_depend

CDEPEND="${CDEPEND:-}
	${PYTHON_DEPS}"

DEPEND="${CDEPEND:-}
	${DEPEND:-}"

HDEPEND="${HDEPEND:-}
	${PYTHON_DEPS}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND:-}
	app-emulation/qubes-core-agent-linux[qubes-rpc_GetImageRGBA(+)]
	nautilus? (
		dev-python/nautilus-python
		dev-python/pygobject
	)
	svg? ( app-emulation/qubes-core-agent-linux[qubes-RGBA_svg(+)] )
	xdg-icon? ( app-emulation/qubes-core-agent-linux[qubes-RGBA_xdg-icon(+)] )
	zenity? ( gnome-extra/zenity )"

#	selinux? ( sec-policy/selinux-qubes-img-coverter )

#todo:allow qarma in place of zenity


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

pkg_setup() {

	python-single-r1_pkg_setup
}

src_prepare() {

	eapply_user

	use gnome || sed -i -e '/[-.]gnome /d' -- "${S}/Makefile"
	use nautilus || sed -i -e '/nautilus/d' -- "${S}/Makefile"

	if use gnome && ! use zenity; then

		for file in 'qvm-convert-image-gnome' 'qvm-convert-image.gnome'; do

			cp -- "${S}/${file}" "${T}/${file}"
			cat -- "${T}/${file}" | tr '\n' '\v' | sed -e 's/\ \\\s*\s|\szenity.*$/\v/' -- - | tr '\v' '\n' | cat -- - > "${S}/${file}"
			rm -- "${T}/${file}"

		done

	fi
}

src_compile() {

	true
}

src_install() {

	emake DESTDIR="${D}" install

	[ -e "${D}/usr/share/nautilus-python/extensions" ] && python_optimize "${D}/usr/share/nautilus-python/extensions/"*'.py'
	[ -e "${D}/usr/lib/qubes" ] && fowners :qubes '/usr/lib/qubes'
	[ -e "${D}/usr/lib/qubes" ] && fperms 0710 '/usr/lib/qubes'
}
