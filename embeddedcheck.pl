#!/usr/bin/perl
#
# Checks embedded certificate in an entity fragment file
#
# TODO:
# - Check that xml_grep exists on this machine
# - Work out why system checkcert.sh outputs "-e"
# - report on whether this is signing/encryption/useless (NB: duplicate certs)

$DEBUG = 0;

sub usage() {

	print <<EOF;
	
	usage: $0 <entity fragment file>
	
	Runs the check certificate script on all the embedded certificates
	
EOF

}

if ( ! "$ARGV[0]" ) {
	print "\nError: You must supply a readable entity fragment file as the first argument\n";
	usage();
	exit 1;
}

if ( $ARGV[0] =~ m/^-[hH]/) {
	usage();
	exit 0;
}

if ( ! -r "$ARGV[0]" ) {
	print "\nError: $ARGV[0] must be a readable entity fragment file\n";
	usage();
	exit 2;
}

$fragment = $ARGV[0];
$DEBUG && print "DEBUG: entity fragment file is $fragment\n";

$n_certificates = 0;
open(CERTS, "xml_grep 'ds:X509Certificate' $fragment |") || die;
while (<CERTS>) {
	if (/<ds:X509Certificate/) {
		$thiscert = "";
		$DEBUG && print "DEBUG: found a certificate block\n";
		# Sometimes the first line of the certificate is on the same line as the opening tag
		if ( $_ =~ m/<ds:X509Certificate>\s*(\S+)\s*$/ ) {
			$thiscert = "$1\n";
		}
		# simpleSAMLphp puts whole certificate on one line
		if ( $thiscert =~ m!^\s*(\S+)\s*</ds:X509Certificate>! ) {
			$DEBUG && print "DEBUG: Looks like simpleSAMLphp\n";
			$thiscert = $1;
		} else {
			while (($certline = <CERTS>) !~ m/X509Certificate/ ) {
				$thiscert .= $certline;
			}
			# And sometimes the last line of certificate is on same line as closing tag
			if ( $certline =~ m!^\s*(\S+)\s*</ds:X509Certificate>! ) {
				$thiscert .= $1;
			}
		}
		chomp $thiscert;
		$DEBUG && print "DEBUG: left a certificate block\n";
		$DEBUG && print "DEBUG: found certificate is:\n$thiscert\n";
		if ($seen{$thiscert}) { 
			$DEBUG && print "DEBUG: this certificate has already been seen\n";			
		} else {
			$certificates[$n_certificates] = $thiscert;
			++$n_certificates;
		}
		$seen{$thiscert} = 1;
		
	}
}
close CERTS;
$DEBUG && print "DEBUG: Have finished reading in $n_certificates certificates\n";
if ($n_certificates == 0) {
	print "Warning: no certificates found\n";
}

foreach $thiscert (@certificates) {
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
	$TMPFILE=<TMPFILE>;
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
#	system ("checkcert.sh $TMPFILE") || die;
#	open(CERT, "checkcert.sh $TMPFILE |") || die;
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
        print "\n";
        open(CERT, "/usr/bin/openssl x509 -noout -fingerprint -in $TMPFILE |") || die;
        while(<CERT>) {
                s/^-e//; # I don't know why I see '-e' in the raw output. It's removed
                print;
        }

# Remove temporary file	
	unlink $TMPFILE;
}

END {
        print "\n\nWARNING: this version of $0 doesn't have certificate checks\n\n";
}
