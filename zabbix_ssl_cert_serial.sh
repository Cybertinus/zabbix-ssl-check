#!/bin/env bash

# check if the specified cert exists
certpath="${1}"
if [ -z "${certpath}" ] ; then
	echo 'No certificate specified, please specify a path to a valid certificate in the first argument'
	exit 1
elif [ ! -f "${certpath}" ] ; then
	echo "The certificate '${certpath}' does not exist" 1>&2
	exit 2
elif [ ! -r "${certpath}" ] ; then
	echo "No permissions to read the certificate '${certpath}'" 1>&2
	exit 3
fi

openssl x509 -in "${certpath}" -noout -text >/dev/null 2>&1
if [ "${?}" -ne 0 ] ; then
	echo "The specified certificate '${certpath}' is an invalid certificate file" 1>&2
	exit 4
fi

# Extract the expire time from the certificate, and output the human readable form
openssl x509 -in "${certpath}" -noout -text | grep -A 1 'Serial Number' | tail -n 1 | awk '{print $1}'
