#!/usr/bin/perl -wp
#
# Filter that takes an imported.xml file from the build process and moves
# the ID and entityID to the last atributes in the EntityDescriptor element.
#
# Usage: filter_attribute_location.pl < imported.xml 
# Output: XML with nicely formatted <entityDescriptor attributes to STDOUT
#
# TODO: abstract this out so that we can move arbitrary attributes around in an tag
#
# Assumptions:
# - the imported.xml file has the EntityDescriptor all on a single line
# - one or more whitespaces before each attribute (see http://www.w3.org/TR/REC-xml/#AVNormalize)
# - no double quotes within an attribute value, even if backslash-protected
# - can't use XSLT 'cos the original XML is correct, just not formatted well.

BEGIN
{
	$is_ID = 0;
	$is_entityID = 0;
	$re_ID='ID\s*=\s*\".*?\"';
	$re_entityID='entityID\s*=\s*\".*?\"';
}

if (/<EntityDescriptor/) 
{
	if (/<EntityDescriptor[^>]*\s+($re_ID)/) {
		$is_ID=1;
		$ID=$1;
	}
	if (/<EntityDescriptor[^>]*\s+($re_entityID)/) {
		$is_entityID=1;
		$entityID=$1;
	}
	if ($is_ID && $is_entityID) {
		s/\s+$re_ID\s*/ /;
		s/\s+$re_entityID\s*/ /;
		s/(<EntityDescriptor.*?)>/$1 $ID $entityID>/;
	}
}

