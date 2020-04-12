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

# Extract the expire time from the certificate, but still in human readable form
expire_string="$(openssl x509 -in "${certpath}" -noout -text | grep 'Not After' | cut -d ':' -f 2- | sed 's/^ //')"
# Convert the expire time to an epoch timestamp
expire_timestamp="$(date --date="${expire_string}" +%s)"
# Find the current epoch timestamp
now_timestamp="$(date +%s)"

# Check if the certificate isn't expired yet
if [ "${expire_timestamp}" -gt "${now_timestamp}" ] ; then
	# No, the timestamp is still in the future, thus output the timestamp, so Zabbix can process it further
	echo $(( ${expire_timestamp} - ${now_timestamp} ))
else
	# Yes, the timestamp is in the past, thus the certificate has expired, echo a 0 so Zabbix can raise serious alarms
	echo 0
fi
