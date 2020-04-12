#!/bin/env bash

# Create a temp file where the json output can be temporarily stored in
tempfile=$(mktemp)

trap "rm -rf "${tempfile}";" EXIT SIGINT SIGTERM SIGKILL

# Start the JSON output
{
	echo -n '['

	##########
	# APACHE #
	##########
	# Check if Apache is installed on this system
	if [ -d '/etc/apache2' ] ; then
		apacheconfdir='/etc/apache2'
	elif [ -d '/etc/httpd' ] ; then
		apacheconfdir='/etc/httpd'
	else
		apacheconfdir=''
	fi

	# Find the certificates for Apache, if it is installed
	if [ -n "${apacheconfdir}" ] ; then
		certpaths="$(grep -r SSLCertificateFile /etc/apache2 | grep -v 'default-ssl.conf' | awk '!/#/ {print $3}' | sort | uniq)"
		for certpath in ${certpaths}; do
			echo -n "${certpath}" | sed 's/^/{"{#CERTPATH}": "/;s/$/"},/'
		done
	fi

	echo -n ']'
} > "${tempfile}"

sed 's/},]/}]/' ${tempfile}
