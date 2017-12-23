#!/bin/sh

# List of services enabled by default (in case of absence of qubesdb entry)
readonly DEFAULT_ENABLED_NETVM="network-manager qubes-network qubes-update-check qubes-updates-proxy"
readonly DEFAULT_ENABLED_PROXYVM="meminfo-writer qubes-network qubes-firewall qubes-netwatcher qubes-update-check"
readonly DEFAULT_ENABLED_APPVM="meminfo-writer cups qubes-update-check"
readonly DEFAULT_ENABLED_TEMPLATEVM="$DEFAULT_ENABLED_APPVM updates-proxy-setup"
DEFAULT_ENABLED="meminfo-writer"

readonly QDB_READ="qubesdb-read"
readonly QDB_LS="qubesdb-multiread"


read_service() {

    "${QDB_READ}" "/qubes-service/${1}" 2> /dev/null
}


# Set default services depending on VM type
readonly TYPE="$(${QDB_READ} /qubes-vm-type 2>> /dev/null)"
[ "$TYPE" = "AppVM" ] && readonly DEFAULT_ENABLED="$DEFAULT_ENABLED_APPVM"
[ "$TYPE" = "NetVM" ] && readonly DEFAULT_ENABLED="$DEFAULT_ENABLED_NETVM"
[ "$TYPE" = "ProxyVM" ] && readonly DEFAULT_ENABLED="$DEFAULT_ENABLED_PROXYVM"
[ "$TYPE" = "TemplateVM" ] && readonly DEFAULT_ENABLED="$DEFAULT_ENABLED_TEMPLATEVM"

# Enable default services
for srv in ${DEFAULT_ENABLED}; do
    touch -- "/var/run/qubes-service/${srv}"
done

# Enable services
for srv in $(${QDB_LS} /qubes-service/ 2>>/dev/null |grep ' = 1'|cut -f 1 -d ' '); do
    touch -- "/var/run/qubes-service/${srv}"
done

# Disable services
for srv in $(${QDB_LS} /qubes-service/ 2>>/dev/null |grep ' = 0'|cut -f 1 -d ' '); do
    rm -f -- "/var/run/qubes-service/${srv}"
done

exit 0
