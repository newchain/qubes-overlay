# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit qubes

DESCRIPTION='Qubes meta package'
HOMEPAGE='https://github.com/QubesOS'

#IUSE="art gpg gui img input iptables net smartcard sockets sound template usb"
IUSE="gpg gui img input iptables net sockets sound template usb"
qubes_keywords
LICENSE='GPL-2'

qubes_slot

if [ "${SLOT}" != '0/20' ]; then

	RDEPEND="${RDEPEND:-}
		app-emulation/qubes-core-qubesdb:${SLOT}
		template? ( app-emulation/qubes-core-qubesdb[template(+)] )"

fi

RDEPEND="${CDEPEND:-}
	${RDEPEND:-}
	app-emulation/qubes-core-agent-linux:${SLOT}
	gui? (
		app-emulation/qubes-gui-agent-linux:${SLOT}
		x11-drivers/xf86-video-dummyqbs:${SLOT}
		x11-drivers/xf86-input-qubes:${SLOT}
		template? ( app-emulation/qubes-gui-agent-linux[template(+)] )
	)
	gpg? ( app-crypt/qubes-gpg-split )
	img? ( media-gfx/qubes-img-converter )
	input? ( app-emulation/qubes-input-proxy )
	iptables? ( app-emulation/qubes-core-agent-linux[iptables(+)] )
	net? ( app-emulation/qubes-core-agent-linux[net(+)] )
	sockets? ( net-proxy/socat_qrexec )
	template? ( app-emulation/qubes-core-agent-linux[template(+)] )"

#	art? ( media-gfx/qubes-artwork )
#	smartcard? ( app-crypt/qubes-app-yubikey )

REQUIRED_USE="
	iptables? ( net )"


src_unpack() {

	mkdir -p "${S}"
}
