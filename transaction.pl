#!/usr/bin/perl -w
#
use strict;
use Getopt::Long;

sub help {
	print<<'EOF';

usage: transaction.pl [--help] [--head] [--app <applicationId>] [--idp <entityID>] [--ip <IPaddress>] [--saml1] [--saml2] <file>

Summarises data from a Shibboleth transaction.log file.

--help			- prints this help and exits

--app <applicationId>	- only those transactions that are to a particular <applicationId>
--idp <entityID>	- only those transactions that are authenticated from IdP <entityID>
--ip <IPaddress>	- only those transactions that are from client <IPaddress>
--saml1			- only those transactions that are SAML1
--saml2			- only those transactions that are SAML2
	(NB: if neither --saml1 or --saml2 is input, then both SAML1 and SAML2 transactions are reported)

--head			- prints a descriptive header above results

EOF
}

my $app;
my $idp;
my $ip;
my $saml1;
my $saml2;
my $help;
my $head;

my $result = GetOptions(
		"app=s" => \$app,
		"idp=s" => \$idp,
		"ip=s" => \$ip,
		"saml1" => \$saml1,
		"saml2" => \$saml2,
		"help" => \$help,
		"head" => \$head
		);

if ($help) {
	help();
	exit 0;
}

if (!$ARGV[0]) {
	print "Error: you must define an input file\n";
	help();
	exit 1;
}

if (! -r $ARGV[0]) {
	print "Error: input file must be readable\n";
	help();
	exit 2;
}

# if neither --saml1 or --saml2 is input, then both SAML1 and SAML2 transactions are reported
if (!$saml1 && !$saml2) {
	$saml1 = 1;
	$saml2 = 1;
}

open(FILE, $ARGV[0]) || die "Could not open $ARGV[0] for reading";

if ($head) {
	print "# datestamp, transaction, applicationId, IdP, Client IP, Protocol\n";
}

while (<FILE>) {
	if (/: New session/) { 
#		print "New session\n"; 
		/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) .*\[(\d+)\]:.*\(applicationId:\s*(.*?)\).*?IdP: (.*?)\) at \(ClientAddress: (.*?)\).*urn:oasis:names:tc:SAML:(\d)/;
		my $datestamp = $1;
		my $transaction = $2;
		my $applicationId = $3;
		my $entityID = $4;
		my $clientIP = $5;
		my $saml = $6;
		next if ($idp && ($entityID ne $idp));
		next if ($app && ($applicationId ne $app));
		next if ($ip && ($clientIP ne $ip));
		next if ($saml == 1 && !$saml1);
		next if ($saml == 2 && !$saml2);
		print "$datestamp, $transaction, $applicationId, $entityID, $clientIP, SAML$saml\n";
	}
}






