#!/bin/env bash

# Check if there are two arguments present
if [ "${#}" -ne 2 ] ; then
	echo 'Invalid number of arguments given, the first argument should be a domain name, the second one the type of check you want to perform' 1>&2
	exit 1
# Check if the specified check is a portnummer in /etc/services
elif [ -z "$(grep "^${2}[[:blank:]]" /etc/services)" ] ; then
	echo "Unsupported check '${2}' specified, please specify a portname from /etc/services" 1>&2
	exit 2
fi

# Check if it is a valid domainname
host "${1}" > /dev/null 2>&1
if [ "${?}" -ne 0 ] ; then
	echo "Unknow domain '${1}' specified, can't continue" 1>&2
	exit 3
fi

# Store the arguments in human readable variablenames
domainname="${1}"
service="${2}"

# Extract the expire timestamp from the actual webserver
openssl s_client -servername "${domainname}" -connect "${domainname}":"${service}" < /dev/null 2> /dev/null | openssl x509 -noout -enddate | cut -d '=' -f 2
