#!/bin/bash

readonly script_name=$(basename "${0}")

usage() {
	cat <<EOF
Usage: ${script_name} [OPTIONS]
    -u Device UUID
    -a Balena API endpoint
    -r Balena registry endpoint
    -t Balena API token
    -h Display usage
EOF
}

# Remove last two lines so all tests are not executed when sourced
head -n -2 /device-diagnostics/scripts/checks.sh > /tmp/checks.sh

function test_ntp() {
	if ! ntpdate -q ${external_fqdn} > /dev/null 2>&1; then
		echo "${FUNCNAME[0]}: NTP sync failed for upstream: ${external_fqdn}"
	fi
}

function test_dns() {
	local _default_dns="8.8.8.8"
	for j in "${external_fqdn}" "$(echo "${API_ENDPOINT}" | sed -e 's@^https*://@@')"; do
		if ! nslookup "${j}" "${_default_dns}" > /dev/null 2>&1; then
			echo "${FUNCNAME[0]}: DNS lookup failed for ${j} via upstream: ${_default_dns}"
		fi
	done
}

# https://www.balena.io/docs/reference/OS/network/2.x/#network-requirements
function check_site()
{
	tests=(
		# Internet connectivity
		test_ping
		test_ipv4_stack
		test_ipv6_stack
		# 53 UDP - For DNS name resolution.
		test_dns
		# 123 UDP - For NTP time synchronization.
		test_ntp
		# 443 TCP
		test_balena_api
		test_balena_registry
	)
	run_tests "${FUNCNAME[0]}" "${tests[@]}"
}

main() {
	while getopts "hu:t:r:a:" c; do
		case "${c}" in
			u) UUID="${OPTARG:-}";;
			a) API_ENDPOINT=${OPTARG:-};;
			r) REGISTRY_ENDPOINT=${OPTARG:-};;
			t) DEVICE_API_KEY=${OPTARG:-};;
			h) usage;exit 1;;
			*) usage;exit 1;;
		esac
	done

	if [ -z "${UUID}" ]; then
		echo "Missing device UUID"
	elif [ -z "${REGISTRY_ENDPOINT}" ]; then
		echo "Missing registry endpoint"
	elif [ -z "${API_ENDPOINT}" ]; then
		echo "Missing API endpoint"
	elif [ -z "${DEVICE_API_KEY}" ]; then
		echo "Missing API token"
	fi
	if [ -z "${UUID}" ] ||
		[ -z "${REGISTRY_ENDPOINT}" ] ||
		[ -z "${API_ENDPOINT}" ]||
		[ -z "${DEVICE_API_KEY}" ]; then
		usage
		exit 1
	fi

	echo "[${API_ENDPOINT}][${REGISTRY_ENDPOINT}] Running for UUID ${UUID} and API token ${DEVICE_API_KEY}"
	# Unset command line parameters so they are not used in the sourced file
	unset params
	set -- "${params[@]}"
	source /tmp/checks.sh
	check_site | jq -s 'add | {checks:.}'
}

main "${@}"
