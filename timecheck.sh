#!/bin/bash
#
# Checks whether the machine is synchronised with a remote URL
#
# Works on CentOS. MacOSX doesn't have --rfc-3339 nor --date=
#

if [ -z "$1" ]; then
	echo "Error: must give a URL to check"
	exit 1
fi

URL=$1

UDATE=$(date --rfc-3339=seconds)
HOSTUNAME=$(uname -n)
RAWDATE=$(curl --silent --head $URL | grep '^Date' | perl -pe 's/^Date: //; s/\r//')
# HOSTDATE after RAWDATE because we want as little time between remote server
# making the timestamp and our host's timestamp
HOSTDATE=$(date +%s)
REMOTEDATE=$(date --date="$RAWDATE" +%s)
DELTA=$(dc -e "$HOSTDATE $REMOTEDATE - p")

echo "$UDATE, $HOSTUNAME, $HOSTDATE, $URL, $REMOTEDATE, $DELTA"
