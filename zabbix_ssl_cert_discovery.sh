#!/bin/env bash

# Create a temp file where the json output can be temporarily stored in
tempfile=$(mktemp)

trap "rm -rf "${tempfile}";" EXIT SIGINT SIGTERM SIGKILL

function to_json_objects() {
	for certpath in ${1}; do
		certname="$(openssl x509 -in "${certpath}" -noout -subject | sed -ne 's/^.*CN[ ]*=[ ]*//p')"
		echo -n "${certpath}" | sed "s/^/{\"{#CERTPATH}\": \"/;s/$/\", \"{#CERTNAME}\": \"${certname}\", \"{#CHECKTYPE}\": \"${2}\"},/"
	done

}

# Start the JSON output
{
	# JSON start
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
		to_json_objects "$(grep -r SSLCertificateFile "${apacheconfdir}" 2> /dev/null | grep -v 'default-ssl.conf' | awk '!/#/ {print $3}' | sort | uniq)" https
	fi

	#########
	# NGINX #
	#########
	# Find the certificates for Nginx, if it is installed
	if [ -d "/etc/nginx" ] ; then
		to_json_objects "$(grep -r ssl_certificate /etc/nginx/ 2> /dev/null | awk '!/ssl_certificate_key/ {print $3}' | sed 's/;$//' | sort | uniq)" https
	fi

	# JSON end
	echo -n ']'
} > "${tempfile}"

sed 's/},]/}]/' ${tempfile}
