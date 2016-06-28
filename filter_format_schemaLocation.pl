#!/usr/bin/perl -wp
#
# Filter to take an imported.xml file from the build process
# and format it for people. 
#
# Usage: filter_format_schemaLocation.pl < imported.xml 
# Output: XML with nicely formatted <entityDescriptor attributes to STDOUT
#
BEGIN
{
	$UKindent='    '; # 4 spaces
	$re_schemaLocation='xsi:schemaLocation\s*=\s*\".*?\"';
}

if (/<EntityDescriptor/ && /($re_schemaLocation)/) 
{
	$schemaLocation=$1;
	$schemaLocation=~ s/\.xsd\s+/.xsd\n$UKindent/g;
	$_ =~ s/$re_schemaLocation/$schemaLocation/;
}

