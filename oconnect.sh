#!/bin/sh
#
# Wrapper for "openssl s_client -connect"
#

#
# Where the key and certificate files are (needed for MacOS X querying Tomcat)
#
# If you need to make a new key/certificate pair, use these:
# cd $KEYDIR
# openssl genrsa 2048 > oconnect.key
# openssl req -new -key oconnect.key -out oconnect.csr
# openssl x509 -req -days 3650 -in oconnect.csr -signkey oconnect.key -out oconnect.crt
#
KEYDIR="${HOME}/bin"
KEY="${KEYDIR}/oconnect.key"
CERT="${KEYDIR}/oconnect.crt"

#
# Connection information
#
HOST=${1:-localhost}
PORT=${2:-443}
CONNECT="${HOST}:${PORT}"

#
# Do the work
#
echo '^D' | openssl s_client -connect $CONNECT -key $KEY -cert $CERT

