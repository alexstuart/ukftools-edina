#!/bin/sh
#
# Given a domain name as input, this script determines the certificates
# protecting ports 443 and 8443 on the domain name.
#
# Relies on oconnect.sh
#
# .all. has all the output from oconnect.sh
# .443. and .8443. have either the certificate or the error message
#
HOST=${1:-localhost}

DATE=`/bin/date -u '+%Y-%m-%dT%H:%M:%SZ'`
FILE_ALL="${HOST}.all.$DATE"
FILE_443="${HOST}.443.$DATE"
FILE_8443="${HOST}.8443.$DATE"
FILE_TMP="${HOST}.tmp.$DATE"

if [ -e $FILE_ALL ]; then
	echo "ERROR: file $FILE_ALL exists"
	exit 1
fi
touch $FILE_ALL
if [ -e $FILE_443 ]; then
	echo "ERROR: file $FILE_443 exists"
	exit 1
fi
touch $FILE_443
if [ -e $FILE_8443 ]; then
	echo "ERROR: file $FILE_8443 exists"
	exit 1
fi
touch $FILE_8443
if [ -e $FILE_TMP ]; then
	echo "ERROR: file $FILE_TMP exists"
	exit 1
fi
touch $FILE_TMP

oconnect.sh $HOST 443 2>&1 | tee -a $FILE_443
oconnect.sh $HOST 8443 2>&1 | tee -a $FILE_8443
cat $FILE_443 $FILE_8443 > $FILE_ALL

grep -q 'BEGIN CERTIFICATE-----' $FILE_443
RETVAL=$?
if [ $RETVAL == 0 ]; then
	mv $FILE_443 $FILE_TMP
	sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' < $FILE_TMP > $FILE_443
fi
grep -q 'BEGIN CERTIFICATE-----' $FILE_8443
RETVAL=$?
if [ $RETVAL == 0 ]; then
	mv $FILE_8443 $FILE_TMP
	sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' < $FILE_TMP > $FILE_8443
fi
rm -f $FILE_TMP
