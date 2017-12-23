# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI='https://github.com/QubesOS/qubes-vmm-xen.git'

inherit eutils git-r3 qubes
[ "${PV%%[_-]*}" != '9999' ] && inherit versionator

DESCRIPTION='Qubes patches for app-emulation/xen-tools'
HOMEPAGE='https://github.com/QubesOS/qubes-vmm-xen'
SRC_URI=''

[ "${PV%%[_-]*}" != '9999' ] && KEYWORDS="amd64 x86"
LICENSE='GPL-2'
SLOT='0'

if [ "${PV:0:3}" = '4.1' ] || [ "${PR}" = 'r200' ]
then

	EGIT_BRANCH='xen-4.1'

elif [ "${PV:0:3}" = '4.4' ] || [ "${PR}" = 'r300' ]
then

	EGIT_BRANCH='xen-4.4'

elif [ "${PV:0:3}" = '4.6' ] || [ "${PR}" = 'r320' ]
then

	EGIT_BRANCH='xen-4.6'

else

	EGIT_BRANCH='xen-4.8'

fi

qubes_keys_depend

[ "${PV%%[_-]*}" != '9999' ] && MY_PV="${PV/_p/-}"


src_unpack() {

	readonly version_prefix='v'
	qubes_prepare
}

src_prepare() {

	epatch_user
}

src_compile() {

	echo >> /dev/null
}

src_install() {

	# subslots and paths...
	#
	#readonly xen_tools_patchdir="etc/portage/patches/app-emulation/xen-tools:${SLOT}/"
	readonly xen_tools_patchdir="etc/portage/patches/app-emulation/xen-tools/"

	insinto "${xen_tools_patchdir}"

	j=0
	for i in $(cat "${S}/series-vm.conf" | sed '/qemu-tls-/d;/xen-tools-qubes-vm.patch/d;/xsa155-xen-0003-libvchan-Read-prod-cons-only-once.patch/d')
	do

		j=$((j+1))
		printf -v k "%02d" "${j}"
		newins "${i}" "${k}_${i##*/}"

	done
}
