#!/usr/bin/perl

# Takes multiple Kiwibank XML files and merges them them into
# QIF files. The QIF files are divided into bank account numbers!
# Good for for scraping bank records into GNUcash accountancy software
# Author: Patrick O'Connor (patrick_kiwi@protonmail.ch)

use XML::Simple qw(:strict);
use Finance::QIF;
use Data::Dumper;

my $xmldir = "./xmlfiles/"; #Specify XML directory location
opendir(DIR, "$xmldir");
my @FILES= readdir(DIR);
closedir(DIR);

foreach $file (@FILES) { 
if ($file ne "." && $file ne "..") {#file loop
#print "Loading $file\n";

my $config = XMLin("$xmldir$file", 
KeyAttr => { Account => 'MOD11Number' },
ForceArray => ['Account', 'Transaction', 'Line'],
SuppressEmpty => 1,
); #load XML transactions records into a data container

#print Dumper($config); #For debugging - show data container structure

foreach my $account_number (keys %{$config->{'Account'}}) { #AccountNumberLoop
	my $OUTQIF = Finance::QIF->new( file => ">>${account_number}.qif" ); #define QIF object
	#print "Processing transactions from $account_number\n";
	foreach $tran_ref 
	( @{$config->{'Account'}->{"$account_number"}->{'Transaction'}} ) 
	{ #Transactions (belongning to account number) loop
	my $amount = $tran_ref->{'Lines'}->{'Line'}->[0]->{'Amount'};
	my $date = $tran_ref->{'Date'};
	$date =~ s/(\d+)\-(\d+)\-(\d+)/$3\/$2\/$1/;
	my $payee = $tran_ref->{'Lines'}->{'Line'}->[0]->{'Description'};
	my $memo = $tran_ref->{'Lines'}->{'Line'}->[1]->{'Description'};

		my $record = { #load each transaction into a hash ref
    		header   	=> "Type:Bank", 
    		transaction   	=> "$amount",
    		payee    	=> "$payee",
    		memo     	=> "$memo",
    		date     	=> "$date",
  		};
	
	$OUTQIF->header( $record->{header} );
  	$OUTQIF->write($record);
	%$record = (); #empty the hash ref

	}#Close Transactions (belongning to account number) loop
	
	$OUTQIF->close();
}##Close Account number loop
}##Close File loop
}
	
