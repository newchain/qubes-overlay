# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2


qubes_keys_depend() {

	DEPEND="${DEPEND}
	  app-crypt/gnupg"

	if [ "${PV%%[_-]*}" != '9999' ]
	then

	  DEPEND="${DEPEND}
	    >=app-crypt/qubes-keys-${tag_date:-9999}"

	else

	  DEPEND="${DEPEND}
	    ~app-crypt/qubes-keys-9999"

	fi
}


qubes_slot() {

	case "${PV%%.*}:${PV%.*}:${RR:-}" in

	  2:2*:*)
	    EGIT_BRANCH='release2'
	    SLOT='0/20'
	  ;;

	  3:3.2:*)
	    EGIT_BRANCH='release3.2'
	    SLOT='0/32'
	  ;;

	  3:3.1:*)
	    EGIT_BRANCH='release3.1'
	    SLOT='0/31'
	  ;;

	  3:3*:*)
	    EGIT_BRANCH='release3.0'
	    SLOT='0/30'
	  ;;

	  4:4.2:*)
	    EGIT_BRANCH='master'
	    SLOT='0/41'
	  ;;

	  4:4.1:*)
	    EGIT_BRANCH='master'
	    SLOT='0/41'
	  ;;

	  4:4.0:*)
	    EGIT_BRANCH='master'
	    SLOT='0/40'
	  ;;

	  9999:9999*:r200)
	    EGIT_BRANCH='release2'
	    SLOT='0/20'
	  ;;

	  9999:9999*:r410)
	    EGIT_BRANCH='master'
	    SLOT='0/41'
	  ;;

	  9999:9999*:r400)
	    EGIT_BRANCH='master'
	    SLOT='0/40'
	  ;;

	  9999:9999*:r320)
	    EGIT_BRANCH='release3.2'
	    SLOT='0/32'
	  ;;

	  9999:9999:*)
	    EGIT_BRANCH='master'
	    SLOT='0'
	  ;;

	esac
}


qubes_tag_date() {

	tag_date="$( < ${FILESDIR}/tag_dates)"

	for date in ${tag_date}
	do

	  if [ "${PV}" = "${tag_date%=*}" ]

	    then tag_date="${tag_date#*=}"
		break

	  fi

	done

	[ -z "${tag_date}" ] && unset tag_date


	DEPEND="${CDEPEND}
		app-crypt/gnupg"

	if [ "${PV%%[_-]*}" != '9999' ]
	then

	  DEPEND="${DEPEND}
	    ~app-crypt/qubes-keys-9999"

	else

	  DEPEND="${DEPEND}
	    >=app-crypt/qubes-keys-${tag_date:-9999}"

	fi
}


qubes_prepare() {

	if [ "${PV%%[_-]*}" != '9999' ]
	then

	  EGIT_COMMIT="${version_prefix}${MY_PV:=${PV}}"

	else

	  EGIT_COMMIT='HEAD'

	fi

	git-r3_src_unpack

	cd "${WORKDIR}/${P}"

	if [ "${PN}" != 'qubes-secpack' ]
	then

	  gpg --import '/var/lib/gentoo/gkeys/keyrings/qubes/release/pubring.gpg'
	  gpg --import-ownertrust '/var/lib/gentoo/gkeys/keyrings/qubes/release/trustdb.txt'

	else

	  gpg --import "${FILESDIR}/qubes-developers-keys.gpg"
	  gpg --import-ownertrust "${FILESDIR}/trustdb.txt"

	fi

	for tag in $(git tag --points-at "${EGIT_COMMIT}")
	do

	  # There is no way to specify a specific key =/
	  git verify-tag "${tag}" || die 'Signature verification failed!'

	done
}


# This is lifted from the openrc ebuilds
#
qubes_to_runlevel() {

	if ! [ -e "${EROOT}etc/runlevels/default/${1}" ]
	then

	  elog "Auto-adding ${1} to default runlevel..."

	  ln -snf -- "/etc/init.d/${1}" "${EROOT}etc/runlevels/default/${1}"

	fi
}
