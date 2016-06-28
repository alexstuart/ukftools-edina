#!/bin/bash

WORKSPACE='*** Add your home directory here ***'
UK="${WORKSPACE}/UK-fed-meta"

if [ -z "$1" ]; then
	echo "Error: must supply a UKf ID ukXXXXXX"
	exit 1
fi

ID=$1
fragment="${ID}.xml"

if [ -f "$fragment" ]; then
	echo "Error: file $fragment already exists"
	exit 2
fi

which ant > /dev/null

if [ $? -eq 0 ]; then
	ant -f $UK/build.xml import.metadata
else
	echo "Can't find ant, assuming you've used the Eclipse ant target..."
fi

cat $UK/entities/imported.xml | filter_attribute_location.pl | filter_format_schemaLocation.pl | perl -pe "s/uk000000_CHANGE_THIS/$ID/;" > $fragment
