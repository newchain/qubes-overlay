# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-vmm-xen.git'
EGIT_SUBMODULES=()

inherit git-r3 qubes
[ "${PV%%[_-]*}" != '9999' ] && inherit versionator

DESCRIPTION='Qubes patches for app-emulation/xen-tools'
HOMEPAGE='https://github.com/QubesOS/qubes-vmm-xen'

[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

case "${PV:0:3}" in

	4.8)
		EGIT_BRANCH='xen-4.8'
		sed_expression='/tools-include-sys-sysmacros.h-on-Linux\.patch/d;/xen-tools-qubes-vm\.patch/d'
	;;

	999)
		EGIT_BRANCH='xen-4.8'
		sed_expression='/tools-include-sys-sysmacros.h-on-Linux\.patch/d;/xen-tools-qubes-vm\.patch/d'
	;;

esac

tag_date='20171128'
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

[ "${PV%%[_-]*}" != '9999' ] && MY_PV="${PV/_p/-}"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

pkg_nofetch() {

	einfo "If you already have this specific version locally, retry with EVCS_OFFLINE=1."
}

src_compile() {

	true
}

src_install() {

	# subslots and paths...
	#
	#readonly xen_tools_patchdir="etc/portage/patches/app-emulation/xen-tools:${SLOT}"
	#readonly xen_tools_patchdir="etc/portage/patches/app-emulation/xen-tools${patch_dir_postfix:-}"
	readonly xen_tools_patchdir="/etc/portage/patches/app-emulation/xen-tools"

	#sed -i 's/debian-vm\(\.orig\)*/xen-4.8.0/' -- "${S}/patches.qubes/xen-tools-qubes-vm.patch"
	#mv -- "${S}/patches.qubes/xen-tools-qubes-vm.patch" "${S}/patches.qubes/xen-tools-qubes-vm.patch.old"
	#cat -- "${S}/patches.qubes/xen-tools-qubes-vm.patch.old" | tail -n +3 -- - | cat -- - > "${S}/patches.qubes/xen-tools-qubes-vm.patch"

	diropts -g portage -m 0750
	insopts -g portage -m 0640

	# Automatic dodir does not respect diropts
	edirs="
		/etc/portage
		/etc/portage/env
		/etc/portage/package.env
		/etc/portage/patches
		/etc/portage/patches/app-emulation
		/etc/portage/patches/app-emulation/xen-tools-4.8.2
		/etc/portage/patches/app-emulation/xen-tools-4.9.1
		/etc/portage/profile
		/etc/portage/profile/bashrc
		/etc/portage/profile/package.bashrc"

	dodir ${edirs}

	#cp -- "${FILESDIR}/4.8_xen-tools-qubes-vm.patch" "${S}/patches.qubes/xen-tools-qubes-vm.patch"

	insinto "${xen_tools_patchdir}-4.8.2"
	index=0
	for patch in $(cat -- "${S}/series-vm.conf" | sed -e "${sed_expression}" -- -); do

		index="$(( ${index} + 1 ))"
		printf -v prefix '%02d' "${index}"
		newins "${patch}" "${prefix}_${patch##*/}"

	done

	#cp -- "${FILESDIR}/4.9_xen-tools-qubes-vm.patch" "${S}/patches.qubes/xen-tools-qubes-vm.patch"

	#insinto "${xen_tools_patchdir}-4.9"
	#insinto "${xen_tools_patchdir}:0/4.9"
	#insinto "${xen_tools_patchdir}-4.9*"
	insinto "${xen_tools_patchdir}-4.9.1"
	index=0
	for patch in $(cat -- "${S}/series-vm.conf" | sed -e "${sed_expression}" -- -); do

		index="$(( ${index} + 1 ))"
		printf -v prefix '%02d' "${index}"
		newins "${patch}" "${prefix}_${patch##*/}"

	done

	insinto '/etc/portage/env'
	newins "${FILESDIR}/4.8_env" 'app-emulation.xen-tools-4.8_qubes.conf'
	newins "${FILESDIR}/4.9_env" 'app-emulation.xen-tools-4.9_qubes.conf'

	insinto '/etc/portage/package.env'
	newins "${FILESDIR}/4.8_package.env" 'app-emulation.xen-tools-4.8_qubes'
	newins "${FILESDIR}/4.9_package.env" 'app-emulation.xen-tools-4.9_qubes'

	insinto '/etc/portage/profile/bashrc'
	newins "${FILESDIR}/4.8_bashrc" 'app-emulation.xen-tools-4.8_qubes.conf'
	newins "${FILESDIR}/4.9_bashrc" 'app-emulation.xen-tools-4.9_qubes.conf'

	insinto '/etc/portage/profile/package.bashrc'
	newins "${FILESDIR}/4.8_package.env" 'app-emulation.xen-tools-4.8_qubes.conf'
	newins "${FILESDIR}/4.9_package.env" 'app-emulation.xen-tools-4.9_qubes.conf'
}
