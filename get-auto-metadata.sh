#!/bin/bash
#
# Given an entity fragment file, download the automatically-generated 
# metadata associated with that entity
#
if [ -z "$1" ]; then
	echo "Error: must provide an entity fragment file"
	exit 1
fi

if [ ! -r $1 ]; then
	echo "Error: must provide a readable entity fragment file"
	exit 2
fi

URL=$(grep 'Shibboleth.sso' $1 | perl -pe 's/^.*https/https/; s/".*$//; s!Shibboleth.sso.*$!Shibboleth.sso/Metadata!' | uniq)

if [ ! -z "$URL" ]; then
	curl -k $URL
else
	echo "Warning: no endpoint containing Shibboleth.sso found in $1"
fi
