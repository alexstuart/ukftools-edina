#!/usr/bin/env perl
#
# Checks embedded certificate in an entity fragment file
#
# Author: Alex Stuart, alex.stuart@jisc.ac.uk

# Modern Perl etiquette
use 5.016;      # implies "use strict;"
use warnings;
use autodie;

# Useful modules
use XML::LibXML;
use Getopt::Long;

#
# Defining variables
#
# Options processing
my $help = '';
my $DEBUG = '';
my $sha1 = ''; # if you want SAH1 must specificy explicitly since SHA256 is the default
my $fragment; # The fragment file we're investigating
my $fingerprint; # which fingerprint algorithm 
# Data structures
my %seen; # Hash of certificates that have been seen, key is cert as a string (no spaces)
my $n_certificates = 0; # Number of unique certificates in this fragment file
my @textcertificates; # Array of unique certificates

#
# Subroutines
#
sub usage {

        my $message = shift(@_);
        if ($message) { print "\n$message\n"; }

        print <<EOF;

        usage: $0 [-h|--help] [--debug] [--sha1] <entity fragment file>

        Runs the check certificate script on all the embedded certificates

        --help  - shows this help screen and then exits
        --debug - prints additional debugging information
        --sha1  - uses the deprecated SHA1 fingerprint algorithm (we use SHA256 by default)

EOF
}

#
# Options processing
#
GetOptions (
	'help' => \$help,
	'debug' => \$DEBUG,
	'sha1' => \$sha1
	);

if ($help) {
        usage();
        exit 0;
}

if ( $#ARGV == -1 ) {
        usage('ERROR: You must supply a readable entity fragment file as the first argument');
        exit 1;
}

if ( ! -r "$ARGV[0]" ) {
        usage("ERROR: $ARGV[0] must be a readable entity fragment file");
        exit 2;
}

$fragment = $ARGV[0];
$DEBUG && print "DEBUG: entity fragment file is $fragment\n";

$fingerprint = '-sha256';
if ($sha1) { $fingerprint = '-sha1'; }

#
# Main
#
my $dom = XML::LibXML->load_xml( location => $fragment );
my $xpc = XML::LibXML::XPathContext->new( $dom );
$xpc->registerNs( 'md', 'urn:oasis:names:tc:SAML:2.0:metadata' );
$xpc->registerNs( 'ds', 'http://www.w3.org/2000/09/xmldsig#' );
my @certificates = $xpc->findnodes( '//ds:X509Certificate' );

for my $node ( @certificates ) {
	$DEBUG && print "DEBUG: found a certificate block\n";
	my $cert = $node->to_literal;
	$cert =~ s/\s//g;
	$DEBUG && print "DEBUG: found certificate is:\n$cert\n";
        if ($seen{$cert}) {
        	$DEBUG && print "DEBUG: this certificate has already been seen\n";
        } else {
                $textcertificates[$n_certificates] = $cert;
                ++$n_certificates;
        }
        $seen{$cert} = 1;
}
$DEBUG && print "DEBUG: Have finished reading in $n_certificates certificates\n";
if ($n_certificates == 0) {
        print "Warning: no certificates found in $fragment\n";
}

foreach my $thiscert (@textcertificates) {
        print "========================\n";
        print "Processing a certificate\n";
        print "========================\n";
# make the certificate file standard width
        $thiscert =~ s/\n//g;
        $thiscert =~ s/\s//g;
        $thiscert =~ s/(.{60})/$1\n/g;
        chomp $thiscert;
# Create temporary file
        open(TMPFILE, "mktemp /tmp/embeddedcheck.pl.XXXXXX | ");
        my $TMPFILE=<TMPFILE>;
        chomp $TMPFILE;
        $DEBUG && print "DEBUG: tempfile is $TMPFILE\n";
        close(TMPFILE);
# Make temporary file into a certificate file
        open(TMPFILE, "> $TMPFILE") || die;
        print TMPFILE "-----BEGIN CERTIFICATE-----\n";
        print TMPFILE "$thiscert\n";
        print TMPFILE "-----END CERTIFICATE-----\n";
        close(TMPFILE);
        $DEBUG && print "DEBUG: certificate file is:\n";
        $DEBUG && system("cat $TMPFILE");
# Run the checkcert.sh script
#       system ("checkcert.sh $TMPFILE") || die;
#       open(CERT, "checkcert.sh $TMPFILE |") || die;
# Here's an incomplete reimplementation of the checkcert.sh script
        open(CERT, "/usr/bin/openssl x509 -noout -text -in $TMPFILE |") || die;
        while(<CERT>) {
                s/^-e//; # I don't know why I see '-e' in the raw output. It's removed
                print;
        }
        close CERT;
        print "\n";
        open(CERT, "cat $TMPFILE |") || die;
        while (<CERT>) { print; }
	close(CERT);
        print "\n";
        open(CERT, "/usr/bin/openssl x509 -noout -fingerprint $fingerprint -in $TMPFILE |") || die;
        while(<CERT>) {
                s/^-e//; # I don't know why I see '-e' in the raw output. It's removed
                print;
        }
	close(CERT);
# Remove temporary file 
        unlink $TMPFILE;
}

my @nKeyDescriptors;
my $nKD;
print "\n\nWARNING: this version of $0 doesn't have certificate checks\n\n";
print "\n\nSimple check on number of KeyDescriptors in IdP fragment file\n";
print "Number of KeyDescriptors in IDPSSODescriptor: ";
@nKeyDescriptors = $xpc->findnodes( '//md:IDPSSODescriptor/md:KeyDescriptor' );
$nKD = ($#nKeyDescriptors + 1);
print "$nKD\n";
print "Number of KeyDescriptors in AttributeAuthorityDescriptor: ";
@nKeyDescriptors = $xpc->findnodes( '//md:AttributeAuthorityDescriptor/md:KeyDescriptor' );
$nKD = ($#nKeyDescriptors + 1);
print "$nKD\n";

