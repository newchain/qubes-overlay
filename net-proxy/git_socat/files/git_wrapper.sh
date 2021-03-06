#!/bin/sh

set -o errexit -o noclobber -o noglob -o nounset


clean_env() {

  for env in $(env | \
               cut -d '=' -f 1 -- - | \
               sed -e '/[\ }]/d' \
	  	 -e '/^$/d' -- -)
  do

    for preserve in ${env_keep}; do

      [ "${env}" = "${preserve}" ] && continue 2

    done

    unset "${env}" || true

  done
}


configure() {

  socks_port='9107'
  umask 0077

  [ -z "${exe:-}" ] && readonly exe="$(command -v git)"
  [ -z "${log_file:-}" ] && readonly log_file="${TMP:-/tmp}/git_wrapper.log"
  [ -z "${mtu:-}" ] && readonly mtu='1500'
  [ -z "${scheme:-}" ] && readonly scheme='socks5h'
  [ -z "${socket_dir:-}" ] && readonly socket_dir='/var/run/qrtunnels/git'
  [ -z "${socket_wrapper_iface:-}" ] && readonly socket_wrapper_iface='10'
  [ -z "${libdir:-}" ] && readonly libdir='/usr/lib64'
  [ -z "${socket_wrapper_so:-}" ] && readonly socket_wrapper_so="${libdir}/libsocket_wrapper.so"
  [ -z "${socks_host:-}" ] && readonly socks_host='127.0.0.10'
  [ -z "${socks_port:-}" ] && readonly socks_port='9050'
  [ -z "${env_keep:-}" ] && readonly env_keep="_ EDITOR HOME LANG LESS PAGER PWD PATH SHELL TERM TMP USER"
}


wrapped_command() {

  ALL_PROXY="${scheme}://${socks_host}:${socks_port}" LD_PRELOAD="${socket_wrapper_so}" SOCKET_WRAPPER_DIR="${socket_dir}" SOCKET_WRAPPER_DEFAULT_IFACE="${socket_wrapper_iface}" SOCKET_WRAPPER_MTU="${mtu}" "${exe}" "${@:-}"
}


main() {

  configure
  clean_env
  wrapped_command "${@:-}"
}


main "${@:-}"
