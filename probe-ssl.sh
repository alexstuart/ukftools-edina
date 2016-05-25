#!/bin/bash
#
#
# Requires: bash, openssl, dig, timeout, grep, sed

HOST=${1:-localhost}
PORT=${2:-443}

echo "Testing $HOST:$PORT"


# Check that the host is reachable/resolvable

# rough test for IPv4 address
echo $HOST | grep -q -v '^[0-9\.]*$'
if [ $? != 1 ]; then
# In here if $HOST is a DNS name or localhost. Now test that this host is resolvable
	dig $HOST +short | grep -q '[[:digit:]]'
	if [ $? != 0 ]; then
	echo "Error: $HOST was not resolvable by dig."
	exit 1
	fi
fi

# Several different cipher strings to try
#
# 1. Finds the ciphers enabled by default in openssl
# CIPHERSTRING=$(openssl ciphers)
#
# 2. All TLS1 ciphers that openssl was compiled with 
CIPHERSTRING=$(openssl ciphers -tls1 'ALL:COMPLEMENTOFALL')
#
# 3. This is my interpretation of the UK federation httpd recommendations for IdPs
#CIPHERSTRING='ECDHE-RSA-AES128-SHA256:AES128-GCM-SHA256:RC4:HIGH:!MD5:!aNULL:!EDH:!EXPORT'

# split the colon-seperated string
CIPHERS=$(openssl ciphers -tls1 $CIPHERSTRING | sed 's/:/ /g' ) 

for i in $CIPHERS
do 
	echo -n "Testing cipher $i: "
	RETVAL=$(timeout 2 openssl s_client -cipher $i -connect $HOST:$PORT 2>&1 | sed -n 's/^.*Cipher is //p')
	RETVAL=${RETVAL:-'(NONE)'}
	STATUS=$(echo $RETVAL | grep '(NONE)')	
	STATUS=${STATUS:-exists}
	echo "$STATUS"
done

