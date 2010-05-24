
=head1

load_scale_cvtermprops.pl

=head1 SYNOPSIS

    $load_scale_cvtermpropr.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name 
 -D  database name 
 -i infile 
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

This is a script for loading scale values for SP cvterms. 

The terms usually come from breeders scales  (like the potato cooperators guide).

Infile should be in the following format: 
column 1 : cvterm full id (SP:0000xxx)
column 2 : scale name (this is going to be the cvterm name for the prop type_id) 
column 3 :value ( an integer or a string)

cv_name for scale cvtermprops defaults to 'breeders_scale' 


Each term has a cvterm_id (must load first the cvterms from an obo file using gmod_load_cvterms.pl) and the values are stored as cvtermprops. 
Since potato (and other) breeders like to assign numeric scale to sets of values, these numbers are stored in the 'rank' field, and the values will be the vaalues too. If the value is not numeric, the rank will be automatically incremented, starting from '0'.  Prop values are mapped whenever possible to the SP ontology, and should be mapped whenever possible to PATO. 
Such terms will be used in Chado phenotype table in the 'cvalue' column.
This works mostly for colors and shape names. Other scales, usually describing logical rank (e.g. 1=poor to 9=excellent) will not have natural matching terms in PATO. Such terms will be used in Chado phenotype table in the 'value' column, and the actual text and/or numeric value will be stored, without a PATO id.


=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

May 2010
 
=cut


#!/usr/bin/perl
use strict;
use Getopt::Std; 

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;

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
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } );


#getting the last database ids for resetting at the end in case of rolling back
my $last_cvtermprop_id= $schema->resultset('Cv::Cvtermprop')->get_column('cvtermprop_id')->max; 


open (my $FH, $file) || die "can't open file $file for reading!!" ; 

#my $file=CXGN::Tools::File::Spreadsheet->new($filename);
# sp_term scale_name value name_string
my $cv_name= "breeders scale";

eval {
    my $line_count = 0;
    <$FH>;
    TERM: while ( my $line =<$FH>) {
	#	$line = ~s/\s//g;
	chomp $line;
	my @fields = split (/\t/, $line);
	my $term = $fields[0];
	my $scale_name = $fields[1];
	my $value = $fields[2];
	next TERM if !$term;
	#set rank to undef if it is not numeric 
	my $rank = undef;
	$rank = $value if $value =~ m/\d+$/ ; 
	print STDOUT "term ='$term'\n";
	my ($db, $accession) = split (/:/, $term); 
	my ($dbxref) = $schema->resultset("General::Db")->
	    search( { name => $db})->
	    search_related("dbxrefs", { accession=>$accession});
	if (!defined $dbxref) { croak "no dbxref found for accession $accession! \n" } ; 
	my ($cvterm) = $dbxref->
	    search_related("cvterm");
	
	print "cvterm = " . $cvterm->name() . " prop=$value, rank=$rank, type=$scale_name\n";
	
	my $new_prop= $cvterm->create_cvtermprops({$scale_name=>$value} , {cv_name => $cv_name, autocreate=>1, rank=>$rank, allow_duplicate_values=>1});
	
	while (my ($propname,$cvtermprop)  = each %$new_prop ) {
	    print "stored new cvtermprop: $propname, " . $cvtermprop->value() . " rank = " . $cvtermprop->rank() . " (passed rank = '$rank')\n\n" ; 
	}
	
    }
};

if ($@) { print "An error occured! Rolling backl!\n\n $@ \n\n "; }
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    
    if ($last_cvtermprop_id) { $dbh->do("SELECT setval ('cvtermprop_cvtermprop_id_seq', $last_cvtermprop_id, true)"); }
    else { $dbh->do("SELECT setval ('cvtermprop_cvtermprop_id_seq', 1, false)"); }
    
    
}else {
    print "Transaction succeeded! Commiting cvtermprops! \n\n";
    $dbh->commit();
}
