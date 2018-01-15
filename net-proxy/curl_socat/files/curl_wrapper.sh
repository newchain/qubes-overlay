#!/bin/sh

set -o errexit -o noglob -o nounset


clean_env() {

  for env in $(env | cut -d '=' -f 1 -- - | sed -e '/[\ }]/d;/^$/d' -- -); do

    unset "${env}"

  done
}


configure() {

  socks_port='9109'
  umask 0177

  [ -z "${exe:-}" ] && readonly exe="$(command -v curl)"
  [ -z "${log_file:-}" ] && readonly log_file="${TMP:-/tmp}/curl_wrapper.log"
  [ -z "${mtu:-}" ] && readonly mtu='1500'
  [ -z "${scheme:-}" ] && readonly scheme='socks5h'
  [ -z "${socket_dir:-}" ] && readonly socket_dir='/var/run/qrtunnels/curl'
  [ -z "${socket_wrapper_iface:-}" ] && readonly socket_wrapper_iface='10'
  [ -z "${libdir:-}" ] && libdir='/usr/lib64'
  [ -z "${socket_wrapper_so:-}" ] && readonly socket_wrapper_so="${libdir}/libsocket_wrapper.so"
  [ -z "${socks_host:-}" ] && readonly socks_host='127.0.0.10'
  [ -z "${socks_port:-}" ] && readonly socks_port='9050' || true
}


wrapped_command() {

  LD_PRELOAD="${socket_wrapper_so}" PATH='/dev/null' SOCKET_WRAPPER_DIR="${socket_dir}" SOCKET_WRAPPER_DEFAULT_IFACE="${socket_wrapper_iface}" SOCKET_WRAPPER_MTU="${mtu}" "${exe}" --proxy "${scheme}://${socks_host}:${socks_port}" "${@:-}"
}


main() {

  configure
  clean_env
  wrapped_command "${@:-}"
}


main "${@:-}"
