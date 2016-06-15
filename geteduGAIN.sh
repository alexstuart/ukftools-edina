#!/bin/bash
#
# Downloads the eduGAIN metadata aggregate
#
# NB: a HEAD request gets a "HTTP/1.1 405 Method Not Allowed"
# Tomasz suggested http://mds.edugain.org/feed-sha256.xml
#
# Configuration options:
DIRECTORY='/home/astuart4/eduGAIN/'
eduGAIN='http://mds.edugain.org/feed-sha256.xml'
eduGAINtest='http://mds-test.edugain.org'
# End of configuration options
DATE=`/bin/date -u '+%Y-%m-%dT%H:%M:%SZ'`
FILE="eduGAIN.xml.$DATE"
echo "downloading $eduGAIN and storing in $FILE"
/usr/bin/curl $eduGAIN > ${DIRECTORY}/${FILE} 2>/dev/null
