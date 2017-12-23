#!/bin/sh

set -o errexit -o noglob -o nounset

umask 0600

[ -z "${exe:-}" ] && readonly exe='/usr/bin/curl'
[ -z "${mtu:-}" ] && readonly mtu='1500'
[ -z "${scheme:-}" ] && readonly scheme='socks5h'
[ -z "${socket_dir:-}" ] && readonly socket_dir='/var/run/qrtunnels/curl'
[ -z "${socket_wrapper_iface:-}" ] && readonly socket_wrapper_iface='10'
[ -z "${libdir:-}" ] && libdir='/usr/lib64'
[ -z "${socket_wrapper_so:-}" ] && readonly socket_wrapper_so="${libdir}/libsocket_wrapper.so"
unset libdir || true
[ -z "${socks_host:-}" ] && readonly socks_host='127.0.0.10'
[ -z "${socks_port:-}" ] && readonly socks_port='9050'


for env in $(env | cut -d '=' -f 1 -- - | sed -e '/[\ }]/d;/^$/d' -- -)
do

  unset "${env}"

done


LD_PRELOAD="${socket_wrapper_so}" SOCKET_WRAPPER_DIR="${socket_dir}" SOCKET_WRAPPER_DEFAULT_IFACE="${socket_wrapper_iface}" SOCKET_WRAPPER_MTU="${mtu}" "${exe}" --proxy "${scheme}://${socks_host}:${socks_port}" "${@:-}"
