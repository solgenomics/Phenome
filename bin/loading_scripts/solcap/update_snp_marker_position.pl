
=head1

update_snp_marker_position.pl

=head1 SYNOPSIS

    $this_script.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.

=head2 DESCRIPTION

This script updates the snp position based on the solcap SNP file Infinium annotation v2.10
This is supposed to be the final version from SolCAP

=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

January 2012

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;
use CXGN::Marker::Tools;

use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;
##

our ($opt_H, $opt_D, $opt_i, $opt_t);

getopts('H:i:tD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				    }
    );
my $spreadsheet = CXGN::Tools::File::Spreadsheet->new($file);
my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

####################
eval {
    foreach my $marker_name (@rows) {
        my @marker_ids =  CXGN::Marker::Tools::marker_name_to_ids($dbh,$marker_name);
        if (@marker_ids>1) { die "Too many IDs found for marker '$marker_name'" }
	# just get the first ID in the list (if the list is longer than 1, we've already died)
        my $marker_id = $marker_ids[0];
	if(!$marker_id) {
	    print "Marker $marker_name does not exist in database. SKIPPING!\n";
	    next();
        }
	else {  print "marker_id found: $marker_id\n" }
        my $position = $spreadsheet->value_at($marker_name, 'position');
        $position =~ s/\s+//;
        $position = $position/1000000;
        print "Looking at location $position for marker $marker_name \n";
        my $q = "UPDATE sgn.marker_location SET position = ? WHERE location_id = (SELECT location_id FROM sgn.marker_experiment JOIN sgn.pcr_experiment USING (pcr_experiment_id) JOIN sgn.map USING (map_id) WHERE marker_experiment.marker_id = ? and short_name ilike ?  ) ";
        my $sth = $dbh->prepare($q);
        $sth->execute($position, $marker_id, "%kazuza%pseudomolecule%");
        print "Updated position\n";
    }
};


if ($@) {
    print "An error occured! Rolling backl!\n\n $@ \n\n ";
} elsif ($opt_t) {
    print "TEST RUN. Rolling back! \n\n";
} else {
    print "Transaction succeeded! Commiting ! \n\n";
    $dbh->commit();
}
