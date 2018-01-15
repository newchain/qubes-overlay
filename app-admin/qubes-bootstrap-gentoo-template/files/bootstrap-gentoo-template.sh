#!/bin/sh

##!/bin/busybox sh
##!/bin/dash
export POSIXLY_CORRECT=1

umask 0077

set -o errexit -o noclobber -o noglob -o nounset


check_connected() {

    # Make sure this host's networking stack is untouched

    if ip -s link | sed -e '/^1/,/^2/d' -- - | grep -oe '\([0-9]\{1,\}\s\{1,\}\)\{5,\}' -- - | grep -qe '[1-9]' -- -; then

        log_error 'This host has seen external network activity'

    elif ifconfig | grep -qe '^*lo[ :]' -- -; then

        ifconfig | tail -n +8 -- - | grep -qe 'packets\s\{1,\}[1-9]' -- - && log_error 'This host has seen external network activity'

    elif ifconfig | grep -qe 'packets\s\{1,\}[1-9]' -- -; then

        log_error 'This host has seen external network activity'

    elif ! command -v ip >> /dev/null && ! command -v ifconfig >> /dev/null; then

        log_info 1 'Unable to check for network activity'

    fi

    if command -v ip >> /dev/null; then

        for connection in $(ip link | grep -oe ': [0-9a-zA-Z_-]\{1,\}:' -- - | cut -d ':' -f 2 -- -); do

            if [ "${connection}" = 'lo' ]; then

                ip link set "${connection}" down || true

            else

                ip link set "${connection}" down

            fi
        done

    elif command -v ifconfig >> /dev/null; then

        for connection in $(ifconfig | grep -oe '^[0-9a-zA-Z_-]\{1,\}[ :]' -- - | cut -d ':' -f 1 -- -); do

            ifconfig "${connection}" down

        done

    fi
}


chroot_sync_get_distfiles_list() {

    setfattr -n user.pax.flags -v E -- "${build_dir}/usr/bin/python2.7" || chroot_cmd "setfattr -n user.pax.flags -v E -- '/usr/bin/python2.7'"

    export meta_use
    export packages
    export portage_snapshot_date
    export selinux

        if [ "${selinux}" != '0' ]; then

            chroot_cmd "eselect profile 'hardened/linux/amd64/no-multilib/selinux'"

        else

            chroot_cmd "eselect profile 'hardened/linux/amd64/no-multilib'"

        fi

        chroot_cmd "locale-gen"
        chroot_cmd "eselect locale set 'en_US.UTF-8'"

        chroot_cmd "emerge-webrsync -k --revert=\"${portage_snapshot_date}\""

        chroot_cmd "emerge --deep --fetch --newuse --pretend system world ${packages} | cat -- > '/distfiles_list.txt'"

    clean_distfile_list "${build_dir}/distfiles_list.txt" '/home/user/QubesIncoming/distfiles_list.txt'

    if ! cat -- '/home/user/QubesIncoming/distfiles_list.txt' | grep -qe '^[ebuild' -- -; then

        log_error "Invalid list of distfiles to fetch, try manually"

    fi

    command -v qvm-copy-to-vm >> /dev/null && qvm-copy-to-vm "${fetch_vm}" '/home/user/QubesIncoming/distfiles_list.txt' >> "${log_file}" || true

    log_info 1 "You must fetch distfiles_list.txt on a network-connected host"
}


chroot_build() {

    [ -e "${sources_dir}/distfiles" ] || mkdir -m 0750 -- "${sources_dir}/distfiles"
    set +o noglob
    mv -- "/home/user/QubesIncoming/${fetch_vm}/"* "${sources_dir}/distfiles/"
    chown 0:"${portage_gid}" "${sources_dir}/distfiles/"*
    chmod u=rwX,g=rX,o-rwx "${sources_dir}/distfiles/"*
    cp -a -- "${sources_dir}/distfiles/"* "${build_dir}/usr/portage/distfiles/"
    set -o noglob

    chroot_cmd "emerge -uD system world"

    for package in ${packages}; do

        if [ "$(printf "${package}" | cut -d ';' -f 2 -- -)" = 'oneshot' ]; then

            package="$(printf "${package}" | cut -d ';' -f 1 -- -)"
            chroot_cmd "EVCS_OFFLINE=1 emerge --oneshot \"${package}\""

        else

            chroot_cmd "EVCS_OFFLINE=1 emerge \"${package}\""

        fi

    done

    [ "${selinux}" != '0' ] && chroot_cmd "rlpkg -r -v -a"
}


chroot_cmd() {

    [ -z "${1:-}" ] && log_error "Command to run in chroot missing"

    chroot_prepare

    # without -l:
    #/usr/share/eselect/libs/core.bash: line 126: `eval': is a special builtin

    if unshare -fimnu sh -c 'exit 0'; then

        unshare -fimnu -- chroot "${build_dir}" '/bin/su' -l -c "

            ip link set lo down || ifconfig lo down

            . '/etc/profile'

            ${@}
        "

    else

        chroot "${build_dir}" '/bin/su' -l -c "

            . '/etc/profile'

            ${@}
        "

    fi
}


chroot_prepare() {

    chroot_mountpoints="
        ${build_dir}/dev
        ${build_dir}/proc
        ${build_dir}/sys
    "

    for mountpoint in ${chroot_mountpoints}; do

        [ -e "${mountpoint}" ] || log_error "Mountpoint ${mountpoint} is missing.  Has snapshot been unpacked?"

    done
    unset chroot_mountpoints

    [ -e "${build_dir}/dev/null" ] || mount -o rbind,rslave '/dev' "${build_dir:-}/dev"
    [ -e "${build_dir}/proc/${$}" ] || mount -o hidepid=2 -t proc '/proc' "${build_dir:-}/proc"
    [ -e "${build_dir}/sys/devices" ] || mount -o rbind,rslave '/sys' "${build_dir:-}/sys"
}



clean_distfile_list() {

    [ -z "${1:-}" ] && log_error "Argument one for source must be set"
    [ -z "${2:-}" ] && log_error "Argument one for destination must be set"

    cat -- "${1}" | \
        grep -e '^http' -- - | \
        sort -u -- - | \
        cat -- >> "${2}"
    rm -- "${1}"

}


configure() {

    readonly key_qubes='427F11FD0FAA4B080123F01CDDFA1A3E36879494'
    readonly key_qubes_overlay=''
    readonly key_gentoo_portage_snapshot='DCD05B71EAB94199527F44ACDB6B8C1F96D8BF6D'
    readonly key_gentoo_stage='13EBBDBEDE7A12775DFDB1BABB572E0E2D182910'

    readonly portage_gid='250'

    readonly keyrings="
        gentoo
        qubes
    "

    readonly meta_features="gpg gui img input iptables net pulseaudio socks"

    readonly packages_with_template_flag="
        qubes-core-agent-linux
        qubes-core-qubesdb
        qubes-gui-agent-linux
    "

    readonly packages="
       app-crypt/gentoo-keys::gentoo
       app-crypt/gkeys::gentoo
       app-emulation/qubes-meta::qubes-overlay
       app-emulation/qubes-xen-tools-patches::qubes-overlay
    "

    qubes_git_repos="
        qubes-core-agent-linux.git
        qubes-core-qubesdb.git
        qubes-core-vchan-xen.git
        qubes-linux-kernel.git
        qubes-linux-utils.git
        qubes-secpack.git
        qubes-vmm-xen.git
    "

    exe_name="${0%.sh}"
    readonly exe_name="${exe_name##*/}"

    readonly configuration_locations="
            .
        /rw/config
        /etc/qubes
        /usr/share/qubes
    "

    for location in ${configuration_locations}; do

        path=${location}/${exe_name}.conf
        if [ -e ${path} ]; then

            . "${path}"
            break

        fi

    done
    unset path

    if [ -w '/var/log/qubes' ] || [ -w "/var/log/qubes/${exe_name}.log" ]; then

        readonly log_file="/var/log/qubes/${exe_name}.log"

    else

        readonly log_file="${PWD}/${exe_name}.log"

    fi

    touch -- "${log_file}"

    exec 2>> "${log_file}"

    [ "${DEBUG:-0}" != '0' ] && [ -z "${debug:-}" ] && readonly debug="${DEBUG}"
    [ -z "${debug:-}" ] && readonly debug=0
    [ "${debug}" != '0' ] && [ -z "${verbosity}" ] && readonly verbosity=8
    [ -z "${verbosity:-}" ] && readonly verbosity=1
    [ "${verbosity}" = 9 ] && set -o xtrace

    # For future integration into qubes-builder:

    ARCH="${ARCH:-amd64}"
    BUILDER_DIR="${BUILDER_DIR:-/home/user/qubes-builder}"
    DISTRIBUTION="${DISTRIBUTION:-gentoo}"
    CHROOT_DIR="${CHROOT_DIR:-/mnt/gentoo}"
    CHROOT_DIR="${CHROOT_DIR:-${BUILDER_DIR}/chroot-${DISTRIBUTION}}"
    DIST_BUILD_DIR="${DIST_BUILD_DIR:-/home/user}"
    DIST_SRC="${DIST_SRC:-/usr/portage/distfiles}"
    PACKAGE_SET="${PACKAGE_SET:-vm}"
    PLUGIN_DIR="${PLUGIN_DIR:-$(dirname ${0})}"
    PORTAGE_MIRROR="${PORTAGE_MIRROR:-https://mirrors.kernel.org}"
    SRC_DIR="${SRC_DIR:-qubes-src}"
    BOOTSTRAP_TARBALL="${BOOTSTRAP_TARBALL:-}"
    GENTOO_VARIANT="${GENTOO_VARIANT:-hardened-selinux}"
    #QUBES_FEATURES="${QUBES_FEATURES:-gui iptables net}"
    SELINUX="${SELINUX:-1}"
    #SELINUX_POLICY="${SELINUX_POLICY:-mls}"
    SRC_DIR='src-dir'

    GENTOO_SRC_PREFIX="${GENTOO_SRC_PREFIX:-${PORTAGE_MIRROR}/gentoo}"
    #DIST_SRC="${DIST_BUILD_DIR}/${SRC_DIR}"
    #GENTOO_PLUGIN_DIR="${DIST_BUILD_DIR}/qubes-builder/${SRC_DIR}/builder-gentoo"

    builder_mappings="
        ARCH:arch
        CHROOT_DIR:build_dir
        DEBUG:debug
        GENTOO_VARIANT:snapshot_type
        SRC_DIR:sources_dir
        SELINUX:selinux
        SELINUX_POLICY:selinux_policy"

    log_info 2 "Assigning to builder mappings"

    for pair in ${builder_mappings}; do

        log_info 3 "pair is ${pair}"
        environmentalname="$(printf "${pair}" | cut -d ':' -f 1 -- - )"
        variablename="$(printf "${pair}" | cut -d ':' -f 2 -- - )"
        set +o nounset
        eval environmental="\$${environmentalname:-}"
        eval variable="\$${variablename:-}"
        set -o nounset
        log_info 3 "environmental is ${environmental:-}"
        log_info 3 "environmentalname is ${environmentalname:-}"
        log_info 3 "variable is ${variable:-}"
        log_info 3 "variablename is ${variablename:-}"

        if [ -n "${environmental:-}" ] && [ -z "${variable:-}" ]; then

            log_info 2 "Setting readonly $(eval printf ${variablename}=${environmental})"
            readonly "${variablename}"="${environmental}"
            log_info 2 "${variablename} is now $(eval printf \$${variablename})"

        else

            log_info 2 "${environmentalname} is not set or ${variablename} is already set, skipping"

        fi

    done
    unset environmental environmentalhome variable variablename

    [ -z "${arch:-}" ] && readonly arch='amd64'
    [ -z "${snapshot_type:-}" ] && readonly snapshot_type='hardened-selinux'

    check_connected

    for feature in ${meta_features}; do

        feature_varname="qubes_features_${feature}"
        set +o nounset
        eval value="\$${feature_varname:-}"
        set -o nounset
        [ -z "${value}" ] && eval qubes_features_${feature}=

    done

    if [ "${qubes_features_img:-0}" != '0' ]; then

        qubes_git_repos="
            ${qubes_git_repos}
            qubes-app-linux-img-converter.git
        "

    fi

    if [ "${qubes_features_gpg:-0}" != '0' ]; then

        qubes_git_repos="
            ${qubes_git_repos}
            qubes-app-linux-split-gpg.git
        "

    fi

    if [ "${qubes_features_gui:-0}" != '0' ]; then

        qubes_git_repos="
            ${qubes_git_repos}
            qubes-gui-agent-linux.git
            qubes-gui-common.git
        "

    fi

    if [ "${qubes_features_img:-0}" != '0' ]; then

        qubes_git_repos="
            ${qubes_git_repos}
            qubes-app-linux-img-converter.git
        "

    fi

    if [ "${qubes_features_input:-0}" != '0' ]; then

        qubes_git_repos="
            ${qubes_git_repos}
            qubes-app-linux-input-proxy.git
        "

    fi

    if [ "${qubes_features_pdf:-0}" != '0' ]; then

        qubes_git_repos="
            ${qubes_git_repos}
            qubes-app-linux-pdf-converter.git
        "

    fi

    if [ "${qubes_features_usb:-0}" != '0' ]; then

        qubes_git_repos="
            ${qubes_git_repos}
            qubes-app-linux-usb-proxy.git
        "

    fi

    if [ "${qubes_features_yubikey:-0}" != '0' ]; then

        qubes_git_repos="
            ${qubes_git_repos}
            qubes-app-yubikey.git
        "

    fi

    readonly qubes_git_repos

    meta_use='template'
    for feature in ${meta_features}; do

        feature_flag="qubes_features_${feature}"
        eval feature_value="\$${feature_flag}"

        if [ "${feature_value:-0}" != '0' ]; then

            meta_use="${meta_use} ${feature}"

        fi

    done

    readonly meta_use
    unset feature_flag feature_value


    [ -z "${fetch_vm:-}" ] && readonly fetch_vm='none'
    [ -z "${interactive:-}" ] && readonly interactive=0

    # block devices

    [ -z "${block_size:-}" ] && readonly block_size='4096'
    [ -z "${fs_type:-}" ] && readonly fs_type='ext4'

    [ -z "${build_disk:-}" ] && readonly build_disk='xvdi'
    [ -z "${build_dir:-}" ] && readonly build_dir='/mnt/gentoo'

    [ -z "${portage_separate_disk:-}" ] && readonly portage_separate_disk=1
    [ "${portage_separate_disk}" != '0' ] && [ -z "${portage_disk:-}" ] && readonly portage_disk='xvdj'
    [ "${portage_separate_disk}" != '0' ] && [ -z "${portage_mountpoint:-}" ] && readonly portage_mountpoint="${build_dir}/usr/portage"

    [ "${sources_separate_disk:-0}" != '0' ] && [ -z "${sources_disk:-}" ] && readonly sources_disk='xvdk'
    readonly work_dir='/home/user'
    [ -z "${sources_dir:-}" ] && readonly sources_dir="${work_dir}/src-dir" && log_info 2 "sources_dir was unset, assuming sources are in ${work_dir}/src-dir"


    files=
    for keyring in ${keyrings}; do

        keyring_varname="$(printf ${keyring} | tr '-' '_')"

        file="${sources_dir}/keyrings/${keyring}/release/pubring.gpg"
        readonly key_"${keyring_varname}"_keyring="${file}"
        files="${files} ${file}"

        file="${sources_dir}/keyrings/${keyring}/release/trustdb.gpg"
        readonly key_"${keyring_varname}"_trustdb="${file}"
        files="${files} ${file}"

        file="${sources_dir}/keyrings/${keyring}/release/trustdb.txt"
        readonly key_"${keyring_varname}"_trustdb_txt="${file}"
        files="${files} ${file}"

    done


    for file in ${files}; do

        log_info 2 "sources_dir is ${sources_dir}"
        dir="${build_dir}/${file#${sources_dir}/}"
        dir_origin="${build_dir}/var/lib/gentoo/gkeys/${file#${sources_dir}/}"
        dir_origin_native="/var/lib/gentoo/gkeys/${file#${sources_dir}/}"
        log_info 2 "dir_origin is ${dir_origin}"
        log_info 2 "dir is ${dir}"
        log_info 2 "dir_origin_native is ${dir_origin_native}"
        log_info 2 "file is ${file}"
        log_info 2 "checking existence of ${dir_origin}"
        log_info 2 "checking existence of ${dir}"
        log_info 2 "checking existence of ${dir_origin_native}"
        log_info 2 "checking existence of ${file}"

        if ! ( [ -e "${dir_origin}" ] || [ -e "${dir}" ] || [ -e "${dir_origin_native}" ] || [ -e "${file}" ] ); then

            log_error "${file} does not exist"

        else

            log_info 2 "found ${file}"

        fi

    done

    unset file files keyring_varname

    seconds="$(date +%s)"
    seconds="$(( ${seconds} - 24 * 60 ** 2 ))"
    readonly date="$(date -I --date=@"${seconds}" | sed -e 's/-//g')"
    log_info 2 "Set date to ${date}"
    unset seconds


    # Files

    fetch_files=

    if [ -z "${stage_snapshot:-}" ] && [ "${sources_dir}" = "${work_dir}/src-dir" ]; then

        echo "sources_dir is ${sources_dir}"
        set +o noglob
        stage_snapshot_path="$(printf "${sources_dir}"'/stage3-'"${arch}"'-'"${snapshot_type}"'-'[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'T'[0-9][0-9][0-9][0-9][0-9][0-9]'Z.tar.xz')"
        #stage_snapshot_path="$(find "${sources_dir}/${SRC_DIR}" -name "stage3-${arch}-${snapshot_type}-"[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]"Z.tar.xz" -print)"
        set -o noglob

        log_info 2 "stage_snapshot_path is ${stage_snapshot_path}"
        log_info 2 "Comparing ${stage_snapshot_path} to ${sources_dir}/${SRC_DIR}/stage3-${arch}-${snapshot_type}-[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z.tar.xz"

        if [ "${stage_snapshot_path}" = "${sources_dir}/${SRC_DIR}/stage3-${arch}-${snapshot_type}-[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z.tar.xz" ]; then

            log_info 1 'Missing stage snapshot'
            #fetch_files=
            #print_fetch_files=1

        fi

        log_info 2 "Found stage snapshot at ${stage_snapshot_path}"

        [ -e "${stage_snapshot_path}.CONTENTS" ] || log_error 'Missing portage snapshot CONTENTS file'
        [ -e "${stage_snapshot_path}.DIGESTS.asc" ] || log_error 'Missing portage snapshot DIGESTS.asc file'

        readonly stage_snapshot="${stage_snapshot_path##*/}"
        log_info 2 "Stage snapshot is ${stage_snapshot_path##*/}"

    fi

    if [ -z "${portage_snapshot:-}" ] && [ "${sources_dir}" = "${work_dir}/src-dir" ]; then

        set +o noglob
        portage_snapshot_path="$(printf "${sources_dir}/${SRC_DIR}"'/portage-'[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'.tar.xz')"
        set -o noglob

        log_info 2 "portage snapshot path is ${portage_snapshot_path}"
        log_info 2 "Comparing ${portage_snapshot_path} to ${sources_dir}/${SRC_DIR}/portage-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].tar.xz"

        if [ "${portage_snapshot_path}" = "${sources_dir}/${SRC_DIR}"'/portage-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].tar.xz' ]; then

            log_info 1 'Missing portage snapshot'
            fetch_files="${fetch_files}
                         portage-${date}.tar.xz
                         portage-${date}.tar.xz.gpgsig
                         portage-${date}.tar.xz.md5sum"
            print_fetch_files=1

        fi

        [ -e "${portage_snapshot_path}.md5sum" ] || log_error 'Missing portage snapshot md5sum file'
        [ -e "${portage_snapshot_path}.gpgsig" ] || log_error 'Missing portage snapshot gpg signature file'

        readonly portage_snapshot="${portage_snapshot_path##*/}"
        log_info 2 "Portage snapshot is ${portage_snapshot}"
        readonly portage_snapshot_date="$(printf ${portage_snapshot} | cut -d '-' -f 2 -- - | cut -d '.' -f 1 -- -)"
        log_info 2 "Portage snapshot date is ${portage_snapshot_date}"

    fi

    if [ "${print_fetch_files:-0}" = '1']; then

        print_fetch ${fetch_files}

    fi

    # MAC

    [ -z "${selinux:-}" ] && readonly selinux=1

    [ "${selinux}" != '0' ] && [ -n "${selinux_policy:-}" ] || readonly selinux_policy='mls'


    # Portage make.conf

    [ -n "${x86_extensions:-}" ] || readonly x86_extensions='avx avx2 mmx mmxext sse sse2 sse3 sse4_1 sse4_2 ssse3'
    [ -n "${cflags:-}" ] || readonly cflags='-march=native -O2 -pipe -fomit-frame-pointer'
    [ -n "${ldflags:-}" ] || readonly ldflags=',--hash-style=gnu,--sort-common,-z,combreloc'
    [ -n "${compile_jobs:-}" ] || readonly compile_jobs=6
    [ -n "${portage_features:-}" ] || readonly portage_features='buildpkg nodoc noinfo ipc-sandbox network-sandbox userfetch userpriv usersandbox'
    [ -n "${use:-}" ] || readonly use='-introspection minimal -nls -ptpax'

    [ -z "${use_flag_settings:-}" ] && use_flag_settings=
    readonly use_flag_settings="
        ${use_flag_settings}
        dev-vcs/git:-pcre-jit
        sys-apps/iproute2:-minimal
    "
}


configure_late() {

    if [ -z "${stage_snapshot:-}" ]; then

        set +o noglob
        #stage_snapshot_path="$(find   "${sources_dir}" "stage3-${arch}-${snapshot_type}-"[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]"Z.tar.xz" -print)"
        stage_snapshot_path="$(printf "${sources_dir}/stage3-${arch}-${snapshot_type}-"[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'T'[0-9][0-9][0-9][0-9][0-9][0-9]'Z.tar.xz' | tail -n 1 -- -)"
        set -o noglob

        if [ "${stage_snapshot_path}" = "${sources_dir}/stage3-${arch}-${snapshot_type}"'-[1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]T[0-9][0-9][0-9][0-9][0-9][0-9]Z.tar.xz' ]; then

            log_error 'Missing stage snapshot'

        fi

        [ -e "${stage_snapshot_path}.CONTENTS" ] || log_error 'Missing portage snapshot CONTENTS file'
        [ -e "${stage_snapshot_path}.DIGESTS.asc" ] || log_error 'Missing portage snapshot asc signature file'

        readonly stage_snapshot="${stage_snapshot_path##*/}"
        log_info 2 "stage_snapshot is ${stage_snapshot}"

    fi

    if [ -z "${portage_snapshot:-}" ]; then

        set +o noglob
        portage_snapshot_path="$(printf "${sources_dir}/portage-"[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'.tar.xz' | tail -n 1 -- -)"
        set -o noglob

        if [ "${portage_snapshot_path}" = "${sources_dir}"'/portage-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9].tar.xz' ]; then

            log_error 'Missing portage snapshot'

        fi

        log_info 2 "portage_snapshot_path is ${portage_snapshot_path}"

        [ -e "${portage_snapshot_path}.md5sum" ] || log_error 'Missing portage snapshot md5sum file'
        [ -e "${portage_snapshot_path}.gpgsig" ] || log_error 'Missing portage snapshot gpg signature file'

        readonly portage_snapshot="${portage_snapshot_path##*/}"
        log_info 2 "portage_snapshot is ${portage_snapshot}"
        readonly portage_snapshot_date="$(printf ${portage_snapshot} | cut -d '-' -f 2 -- - | cut -d '.' -f 1 -- -)"
        log_info 2 "portage_snapshot_date is ${portage_snapshot_date}"

    fi
}


copy_sources() {

    mount_portage

    if ! [ -e "${build_dir}/usr/portage/distfiles" ]; then

        mkdir -m 0750 -- "${build_dir}/usr/portage/distfiles"

    fi

    set +o noglob
    cp -n -- "${portage_snapshot_path}"* "${build_dir}/usr/portage/distfiles"
    chown 0:"${portage_gid}" "${build_dir}/usr/portage/distfiles/${portage_snapshot}"*
    chmod g=r,o-rwx "${build_dir}/usr/portage/distfiles/${portage_snapshot}"*
    set -o noglob

    if ! [ -e "${build_dir}/usr/local/portage" ]; then

        mkdir -m 0710 -- "${build_dir}/usr/local/portage"

    else

        chmod 0710 "${build_dir}/usr/local/portage"

    fi

    if ! [ -e "${build_dir}/usr/local/portage/qubes-overlay" ]; then

        cp -nR -- "${sources_dir}/qubes-overlay" "${build_dir}/usr/local/portage"

    fi

    chmod -R u=rwX,g=rX,o-rwx "${build_dir}/usr/local/portage/qubes-overlay"

    if ! [ -e "${build_dir}/usr/portage/distfiles/git3-src" ]; then

        mkdir -m 0730 -p -- "${build_dir}/usr/portage/distfiles/git3-src"

    fi

    for repo in ${qubes_git_repos}; do

        if ! [ -e "${build_dir}/usr/portage/distfiles/git3-src/QubesOS_${repo}" ]; then

            cp -R -- "${sources_dir}/${repo}" "${build_dir}/usr/portage/distfiles/git3-src/QubesOS_${repo}"

        fi

        chmod -R 0770 "${build_dir}/usr/portage/distfiles/git3-src/QubesOS_${repo}"

    done

    portage_paths_chown="
        ${build_dir}/usr/local/portage
        ${build_dir}/usr/portage
        ${build_dir}/usr/portage/distfiles
        ${build_dir}/usr/portage/distfiles/git3-src
    "

    chown -R 0:"${portage_gid}" ${portage_paths_chown}


    if ! [ -e "${build_dir}/root/.gnupg" ]; then

        mkdir -m 0700 -- "${build_dir}/root/.gnupg"

    fi

    for keyring in ${keyrings}; do

        cp -R -- "${work_dir}/.gnupg/gnupg-build-${keyring}" "${build_dir}/root/.gnupg"

        [ ! -e "${build_dir}/var/lib/gentoo/gkeys/keyrings/${keyring}/release" ] && mkdir -m 0755 -p -- "${build_dir}/var/lib/gentoo/gkeys/keyrings/${keyring}/release"

        files="
            pubring.gpg
            trustdb.gpg
            trustdb.txt
        "

        for file in ${files}; do

            if [ -e "${build_dir}/var/lib/gentoo/gkeys/keyrings/${keyring}/release/${file}" ]; then

                continue

            elif [ -e "/var/lib/gentoo/gkeys/keyrings/${keyring}/release/${file}" ]; then

                cp -n -- "/var/lib/gentoo/gkeys/keyrings/${keyring}/release/${file}" "${build_dir}/var/lib/gentoo/gkeys/keyrings/${keyring}/release/${file}"

            elif [ -e "${work_dir}/.gnupg/gnupg-build-${keyring}/${file}" ]; then

                cp -n -- "${work_dir}/.gnupg/gnupg-build-${keyring}/${file}" "${build_dir}/var/lib/gentoo/gkeys/keyrings/${keyring}/release/${file}"

            elif [ -e "${sources_dir}/keyrings/${keyring}/release/${file}" ]; then

                cp -n -- "${sources_dir}/keyrings/${keyring}/release/${file}" "${build_dir}/var/lib/gentoo/gkeys/keyrings/${keyring}/release/${file}"

            else

                log_error "Unable to find ${file} for ${keyring}"

            fi

        done

        unset files

    done
}


find_utils() {

    readonly utils_optional="
        openssl
        setfattr
    "

    readonly utils_needed="
        blockdev
        cat
        chown
        chroot
        cp
        cut
        date
        dd
        echo
        eval
        diff
        fdisk
        gpg
        grep
        head
        mkdir
        mke2fs
        mount
        sed
        sha512sum
        tail
        tar
        tr
        tune2fs
        umount
    "

    for util in ${utils_needed}; do

        if ! command -v "${util}" >> /dev/null; then

            command -v busybox >> /dev/null || log_error "${util} and busybox not found"
            busybox | grep -qe "${util}" -- - || log_error "${util} not found and equivalent applet not included within busybox"
            alias "${util}"="busybox ${util}"

        fi

    done

    if [ "${openssl:-0}" = '1' ]; then

        command -v openssl >> /dev/null || log_error "Unable to find openssl"

    elif command -v openssl >> /dev/null; then

        [ -z "${openssl:-}" ] && readonly openssl='1'

    else

        [ -z "${openssl:-}" ] && readonly openssl='0'

    fi
}


log_error() {

    [ "${interactive}" != '0' ] && echo "${1}"
    echo "${1}" >> "${log_file}"
    exit 1
}


log_info() {

    if [ "${verbosity}" -ge "${1}" ]; then

        shift
        [ "${interactive}" != '0' ] && echo "${1}"
        echo "${1}" >> "${log_file}"

    fi
}


mount_disks() {

    log_info 2 "mounting ${build_disk} at ${build_dir}"
    umount "${build_dir}" || true
    mount -o noatime -- "/dev/${build_disk}" "${build_dir}"

    if [ "${sources_dir}" != "${work_dir}" ]; then

        umount "${sources_dir}" || true
        mount -o noatime,nodev,noexec,nosuid -- "/dev/${sources_disk}" "${sources_dir}"

    fi
}


mount_portage() {

    if [ "${portage_separate_disk}" != '0' ]; then

        log_info 2 "mounting ${portage_disk} at ${portage_mountpoint}"
        umount "${portage_mountpoint}" || true
        mount -o noatime,nodev,noexec,nosuid -- "/dev/${portage_disk}" "${portage_mountpoint}"

    fi
}


prepare_disk() {

    [ -z "${1:-}" ] && log_error "Argument one for disk must be set"
    [ -z "${2:-}" ] && log_error "Argument two for mountpoint must be set"
    [ -z "${3:-}" ] && log_error "Argument three for indicative path must be set"

    if fdisk -l "/dev/${1}" | grep -qe 'Device' -- -; then

        log_error "Partitions exist on disk /dev/${1}"

    fi

    [ -e "${2}" ] && log_info 2 "mountpoint ${2} already exists"
    [ -e "${2}" ] || mkdir -m 0700 -p -- "${2}"

    if mount "/dev/${1}" "${2}" >> /dev/null; then

        log_info 2 "Looking for ${2}/${3}"

        if [ -e "${2}/${3}" ]; then

            log_info 1 "found ${2}/${3}, on ${1} assuming prepared disk"
            return 0

        else

            umount "${2}" >> /dev/null
            log_error "Valid filesystem exists on disk /dev/${1}"

        fi

    fi

    if ! dd if="/dev/${1}" bs=512 count=1; then

        log_error "Unable to read /dev/${1}"

    fi


    disk_size_512="$(blockdev --getsz /dev/${1})"
    log_info 2 "disk size is ${disk_size_512} ($(( ${disk_size_512} * 512 / 1024 ** 3 ))GiB)"
    page_size="4096"
    log_info 2 "page_size is ${page_size}"
    page_size_ratio="$(( ${page_size} / 512 ))"
    log_info 2 "page_size_ratio is ${page_size_ratio}"
    disk_size_pages="$(( ${disk_size_512} / ${page_size_ratio} ))"
    log_info 2 "disk_size_pages is ${disk_size_pages}"
    log_info 2 "Comparing $(( ${disk_size_pages} * ${page_size_ratio} * 512 )) bytes of zeroes with /dev/${1}"

    if ! dd if='/dev/zero' bs="${page_size}" count="${disk_size_pages}" | diff -q -- "/dev/${1}" -; then

        log_error "disk /dev/${1} is not empty"

    else

        log_info 2 "disk /dev/${1} is empty..."

    fi

    unset disk_size_pages disk_size_512 page_size page_size_ratio

    case "${4:-}:${fs_type}" in

        ?*:ext[2-4])
            mke2fs -b "${block_size}" -E root_owner=0:0 -L "${4}" -t "${fs_type}" -U random -- "/dev/${1}" >> "${log_file}" || \
            mke2fs -b "${block_size}" -L "${4}" -- "/dev/${1}" >> "${log_file}"
        ;;

        :ext[2-4])
            mke2fs -b "${block_size}" -E root_owner=0:0 -t "${fs_type}"  -U random -- "/dev/${1}" >> "${log_file}" || \
            mke2fs -b "${block_size}" -- "/dev/${1}" >> "${log_file}"
        ;;

    esac
}


print_fetch(){

    echo "The following files must be fetched:"
    echo "${@}"
}


reconfigure() {

    sed -i -e 's/^\(FEATURES="'"${portage_features}"'\)/\1 webrsync-gpg/' -- "${build_dir}/etc/portage/make.conf"

    if [ "${selinux:-1}" != '0' ]; then

        # Leave around commented for future convenience
        sed -i -e 's/^\(FEATURES="${FEATURES} -selinux\)/#\1/' -- "${build_dir}/etc/portage/make.conf"

    fi
}


unpack_stage() {

    log_info 2 "Extracting stage tarball"

    tar --extract --directory="${build_dir}" --file="${stage_snapshot_path}" --atime-preserve=system --numeric-owner --preserve-order --preserve-permissions --touch --xattrs-include='*.*' --xz || \
    tar -x -C "${build_dir}" -f "${stage_snapshot_path}" -m -J
}


validate_install_files() {

    # Specifying ownertrust makes gpg treat the containing directory as gpghome

    for keyring in gentoo qubes qubes-overlay; do

        [ -e '/var/lib/gentoo/gkeys/keyrings/'"${keyring}" ] [ -e "${work_dir}/.gnupg/gnpg-build-${keyring}" ] || mkdir -m 0700 -p -- "${work_dir}/.gnupg/gnupg-build-${keyring}"

        files="
            pubring.gpg
            trustdb.gpg
            trustdb.txt
        "

        for file in ${files}; do

            if [ -e "${work_dir}/.gnupg/gnupg-build-${keyring}/${file}" ]; then

                continue

            elif [ -e "/var/lib/gentoo/gkeys/keyrings/${keyring}/release/${file}" ]; then

                cp -- "/var/lib/gentoo/gkeys/keyrings/${keyring}/release/${file}" "${work_dir}/.gnupg/gnupg-build-${keyring}/${file}"

            elif [ -e "${sources_dir}/keyrings/${keyring}/release/${file}" ]; then

                cp -- "${sources_dir}/keyrings/${keyring}/release/${file}" "${work_dir}/.gnupg/gnupg-build-${keyring}/${file}"

            else

                log_error "Unable to find ${file} for ${keyring}"

            fi

        done

    done

    unset key_keyring key_trustdb

    log_info 2 "Attempting to validate signature on ${portage_snapshot_path}"

    gpg -v --verify --no-default-keyring --keyring="${work_dir}/.gnupg/gnupg-build-gentoo/pubring.gpg" --status-fd --trustdb-name="${work_dir}/.gnupg/gnupg-build-gentoo/trustdb.gpg" -- "${portage_snapshot_path}.gpgsig" "${portage_snapshot_path}" >> "${log_file}" || log_error "Failed to validate portage snapshot ${portage_snapshot_path}"

    log_info 2 "gpg verification of ${portage_snapshot_path} succeeded using ${work_dir}/.gnupg/gnupg-build-gentoo/pubring.gpg"
    log_info 2 "Attempting to validate signature on ${stage_snapshot_path}"

    gpg -v --verify --no-default-keyring --keyring="${work_dir}/.gnupg/gnupg-build-gentoo/pubring.gpg" --status-fd --trustdb-name="${work_dir}/.gnupg/gnupg-build-gentoo/trustdb.gpg" -- "${stage_snapshot_path}.DIGESTS.asc" >> "${log_file}" || log_error "Failed to validate stage snapshot DIGESTS file ${stage_snapshot_path}.DIGESTS.asc"

    log_info 2 "gpg verification of ${stage_snapshot_path}.DIGESTS.asc succeeded using ${work_dir}/.gnupg/gnupg-build-gentoo/pubring.gpg"
    log_info 2 "Attempting sha512 integrity check of ${stage_snapshot_path}"

    stage_snapshot_sha512="$(cat -- "${stage_snapshot_path}.DIGESTS.asc" | sed -ne "/SHA512\ HASH$/,/${stage_snapshot}/p" -- | head -n 2 -- - | tail -n +2 -- - | cut -d ' ' -f 1 -- -)"
    stage_snapshot_sha512_actual="$(sha512sum -- ${stage_snapshot_path} | cut -d ' ' -f 1 -- -)"

    if [ "${stage_snapshot_sha512}" != "${stage_snapshot_sha512_actual}" ]; then

        log_error "Stage snapshot is corrupt (${stage_snapshot_sha512} != ${stage_snapshot_sha512_actual})"

    fi

    unset stage_snapshot_sha512 stage_snapshot_sha512_actual

    log_info 2 "Successful sha512 integrity check of ${stage_snapshot_path}"

    if [ "${openssl:-0}" != '0' ]; then

        log_info 2 "Attempting whirlpool integrity check for ${stage_snapshot_path}"

        stage_snapshot_whirlpool="$(cat -- "${stage_snapshot_path}.DIGESTS.asc" | sed -ne "/WHIRLPOOL\ HASH$/,/${stage_snapshot}/p" -- | head -n 2 -- - | tail -n +2 -- - | cut -d ' ' -f 1 -- -)"
        stage_snapshot_whirlpool_actual="$(openssl dgst -r -whirlpool ${stage_snapshot_path} | cut -d ' ' -f 1)"

        if [ "${stage_snapshot_whirlpool}" != "${stage_snapshot_whirlpool_actual}" ]; then

            log_error "stage snapshot is corrupt (${stage_snapshot_whirlpool} != ${stage_snapshot_whirlpool_actual})"

        fi

        unset stage_snapshot_whirlpool stage_snapshot_whirlpool_actual

        log_info 2 "Successful whirlpool integrity check of ${stage_snapshot_path}"

    else

        log_info 1 "Skipped whirlpool integrity check for ${stage_snapshot_path}"

    fi
}


write_config() {

    if cat -- "${build_dir}/etc/portage/make.conf" | grep -qe 'INPUT_DEVICES=""'; then

        log_info 1 "Found remnants of otherwise unlikely config, assuming configuration has already been written"
        return 0

    fi

    log_info 2 "Writing configuration in build_dir (${build_dir})"

    sed -i -e 's/^\(\s*hostname\)/#\1/' -- "${build_dir}/etc/conf.d/hostname"
    echo 'hostname="host"' >> "${build_dir}/etc/conf.d/hostname"

    sed -i -e 's:^/:#/:' -- "${build_dir}/etc/fstab"

    cat -- >> "${build_dir}/etc/fstab" << END

/dev/mapper/dmroot	/		${fs_type}	noatime		0 1
/dev/xvdb		/rw		${fs_type}	noatime,nodev,noexec,nosuid,noauto	0 1
/rw/home		/home		none	bind,noatime,nodev,noexec,nosuid,noauto	0 0
proc			/proc		proc	rw,nosuid,nodev,noexec,relatime,hidepid=2	0 0
END

    case "${selinux:-1}:${selinux_policy:-mls}" in

        [!0]*:mls)

            cat -- >> "${build_dir}/etc/fstab" << END
tmpfs			/run		tmpfs	noatime,nodev,noexec,nosuid,rootcontext=system_u:object_r:var_run_t:s0-s15:c0.c1023	0 0
tmpfs			/tmp		tmpfs	noatime,nodev,noexec,nosuid,rootcontext=system_u:object_r:tmp_t:s0-s15:c0.c1023	0 0
END
            ;;

        [!0]*:mcs)

            cat -- >> "${build_dir}/etc/fstab" << END
tmpfs			/run		tmpfs	noatime,nodev,noexec,nosuid,rootcontext=system_u:object_r:var_run_t:s0:c0.c1023	0 0
tmpfs			/tmp		tmpfs	noatime,nodev,noexec,nosuid,rootcontext=system_u:object_r:tmp_t:s0:c0.c1023	0 0
END

        ;;

        [!0]*:strict)

            cat -- >> "${build_dir}/etc/fstab" << END
tmpfs			/run		tmpfs	noatime,nodev,noexec,nosuid,rootcontext=system_u:object_r:var_run_t:s0	0 0
tmpfs			/tmp		tmpfs	noatime,nodev,noexec,nosuid,rootcontext=system_u:object_r:tmp_t:s0	0 0
END

        ;;

        0:*)

            cat -- >> "${build_dir}/etc/fstab" << END
tmpfs			/run		tmpfs	noatime,nodev,noexec,nosuid	0 0
tmpfs			/tmp		tmpfs	noatime,nodev,noexec,nosuid	0 0
END

        ;;

    esac

    cat -- >> "${build_dir}/etc/fstab" << END
/dev/xvdi		/mnt/removable	auto	noatime,nodev,noexec,nosuid,noauto	0 1
/rw/varlib		/var/lib	none	bind,noatime,nodev,noexec,nosuid,noauto	0 1
END

    if [ "${portage_separate_disk}" != '0' ]; then

        cat -- >> "${build_dir}/etc/fstab" << END
/dev/xvdj		/usr/portage	${fs_type}	noatime,nodev,noexec,nosuid,noauto	0 1
END

    fi

    chmod go-rwx "${build_dir}/etc/fstab"

    sed -i -e 's/^\([a-z]\)/#\1/' \
           -e 's/^#\(en_US\.UTF-8\)/\1/' -- "${build_dir}/etc/locale.gen"
    echo 'Etc/UTC' >> "${build_dir}/etc/timezone"

    sed -i -e 's/^\(CX*FLAGS=\|USE=\)/#\1/g' -- "${build_dir}/etc/portage/make.conf"

    cat -- >> "${build_dir}/etc/portage/make.conf" << END

ACCEPT_KEYWORDS="~amd64"

CPU_FLAGS_X86="${x86_extensions}"

CFLAGS="${cflags}"
CXXFLAGS="\${CFLAGS}"
LDFLAGS="\${LDFLAGS}${ldflags}"

MAKEOPTS="${compile_jobs}"

FEATURES="${portage_features}"

INPUT_DEVICES=""
VIDEO_DEVICES=""

PORTAGE_GPG_DIR='/var/lib/gentoo/gkeys/keyrings/gentoo'

PYTHON_SINGLE_TARGET='python2_7'
PYTHON_TARGETS="python2_7"

USE="${use}"
END

    if [ "${selinux}" != '0' ]; then

        # Portage selinux support must be disabled until policy is in place.
        cat >> "${build_dir}/etc/portage/make.conf" << END

SELINUX_POLICY="${selinux_policy}"

# While selinux is disabled or valid policy is not loaded, selinux and sesandbox must be disabled.
FEATURES="\${FEATURES} -selinux -sesandbox"
END

    fi

    portage_chown_paths=
    portage_chown_paths="
        package.use/app-emulation.qubes-meta
        repos.conf/gentoo.conf
        repos.conf/qubes-overlay.conf
    "

    for dir in package.use package.use/app-emulation repos.conf; do

        if ! [ -e "${build_dir}/etc/portage/${dir}" ]; then

            mkdir -m 0750 -- "${build_dir}/etc/portage/${dir}"
        fi

        portage_chown_paths="
            ${portage_chown_paths}
            ${dir}
        "
    done

    umask 0027

    cp -n -- "${build_dir}/usr/share/portage/config/repos.conf" "${build_dir}/etc/portage/repos.conf/gentoo.conf"
    sed -i -e 's/sync-type = .*$/sync-type = webrsync/' \
           -e 's/auto-sync = .*$/auto-sync = no/' -- "${build_dir}/etc/portage/repos.conf/gentoo.conf"

    if ! [ -e "${build_dir}/etc/portage/repos.conf/qubes-overlay.conf" ]; then

        cat -- > "${build_dir}/etc/portage/repos.conf/qubes-overlay.conf" << END
[qubes-overlay]
location = /usr/local/portage/qubes-overlay
masters = gentoo
sync-type = git
sync-uri = https://github.com/newchain/qubes-overlay.git
auto-sync = no
END
    else
        log_info 2 "${build_dir}/etc/portage/repos.conf/qubes-overlay.conf already exists, not writing"
    fi

    printf '%b\n' "app-emulation/qubes-meta ${meta_use}" >> "${build_dir}/etc/portage/package.use/app-emulation.qubes-meta"


    for package in ${packages_with_template_flag}; do

        printf '%b\n' "app-emulation/${package} template" >> "${build_dir}/etc/portage/package.use/app-emulation.${package}"
        portage_chown_paths="
            ${portage_chown_paths}
            package.use/app-emulation.${package}
        "
    done

    if printf '%b\n' "${meta_use}" | grep -qe 'iptables'; then

        printf '%b\n' 'app-emulation/qubes-core-agent-linux iptables net' >> "${build_dir}/etc/portage/package.use/app-emulation.qubes-core-agent-linux"

    fi


    for pair in ${use_flag_settings}; do

        flags="$(printf ${pair} | cut -d ':' -f 2 -- - | tr ';' ' ')"
        package="$(printf ${pair} | cut -d ':' -f 1 -- -)"
        file="$(printf ${package} | tr '/' '.')"

        printf '%b\n' "${package} ${flags}" >> "${build_dir}/etc/portage/package.use/${file}"

    done

    umask 0077

    chown_paths=
    for file in ${portage_chown_paths}; do

        chown_paths="
            ${chown_paths}
            ${build_dir}/etc/portage/${file}
        "
    done

    chown 0:"${portage_gid}" ${chown_paths}
    unset chown_paths portage_chown_paths
}


main() {

    if [ "${1:-}" != 'continue' ] && [ "${1:-}" != 'retry' ]; then

        configure
        find_utils
        prepare_disk "${build_disk}" "${build_dir}" 'etc' 'root'
        [ "${portage_separate_disk:-0}" != '0' ] && prepare_disk "${portage_disk}" "${portage_mountpoint}" 'profiles' 'portage'
        mount_disks
        configure_late
        validate_install_files
        unpack_stage
        copy_sources
        write_config
        chroot_sync_get_distfiles_list

    elif [ "${1:-}" = 'continue' ] || [ "${1:-}" = 'retry' ]; then

        shift
        config
        configure_late
        chroot_build "${@}"
        reconfigure

    fi
}


main "${@}"
