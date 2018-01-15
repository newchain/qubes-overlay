# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-linux-kernel.git'

inherit git-r3 qubes

DESCRIPTION='Qubes patches for Linux kernel sources'
HOMEPAGE='https://github.com/QubesOS/qubes-linux-kernel'

[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

case "${PV:0:4}:${PR:-}" in

	4.14:*)
		EGIT_BRANCH='stable-4.14'
		micro_releases="12 13 14 15"
	;;

	4.9.:*)
		EGIT_BRANCH='stable-4.9'
		micro_releases="75 76 77 78"
	;;

	4.4.:*)
		EGIT_BRANCH='stable-4.4'
		micro_releases="111 112 113 114)"
	;;

	9999:r414)
		EGIT_BRANCH='stable-4.14'
		micro_releases="12 13 14 15"
	;;

	9999:r409)
		EGIT_BRANCH='stable-4.9'
		micro_releases="75 76 77 78"
	;;

	9999)
		EGIT_BRANCH='master'
	;;

esac

[ "${PV%%[_-]*}" != '9999' ] && MY_PV="${PV/_p/-}"


tag_date='20171017'
qubes_keys_depend


HDEPEND="${HDEPEND:-}
	|| (
		sys-apps/coreutils
		sys-apps/busybox
	)
	|| (
		sys-apps/sed
		sys-apps/busybox
	)"

RDEPEND="${CDEPEND:-}"


src_unpack() {

	version_prefix='v'
	qubes_prepare
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

	sed_expression='/^#/d'

	if [ "${EGIT_BRANCH}" != 'master' ]; then

		postfix="${EGIT_BRANCH#stable-}"

		for version in ${micro_releases}; do

			insinto "/etc/portage/patches/sys-kernel/vanilla-sources-${postfix}.${version}"
			index=0
			for patch in $(cat -- "${S}/series.conf" | sed -e "${sed_expression}" -- -); do

				index="$(( ${index} + 1 ))"
				printf -v prefix '%02d' "${index}"
				newins "${patch}" "${prefix}_${patch##*/}"

			done

		done

	else

		insinto '/etc/portage/patches/sys-kernel/vanilla-sources'

		index=0
		for patch in $(cat -- "${S}/series.conf" | sed -e "${sed_expression}" -- -); do

			index="$(( ${index} + 1 ))"
			printf -v prefix '%02d' "${index}"
			newins "${patch}" "${prefix}_${patch##*/}"

		done

	fi
}
