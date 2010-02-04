
=head1 NAME

flag_obsolete_annot.pl

=head1 DESCRIPTION

Usage: perl flag_obsolete_annot.pl -H dbhost -D dbname -o outfile [-v]

parameters

=over 6

=item -H

hostname for database [required]

=item -D

database name [required]

=item -v

verbose output

=item -d

db name of the controlled vocabulary 

=item -o 

output file 

=item -t 

test mode

=back


The script looks for locus and individual  ontology annotations in the database and prints out a 
list of annotations that require updating since the cvterms were obsoleted. 
Ususally running this script is a good idea after updating cvterms in the database (see sgn-tools/phenome/load_cvterms.pl)
and prior to submitting an ontology association file to PO/GO.

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=head1 VERSION AND DATE

Version 0.1, February 2008.

=cut


#! /usr/bin/perl
use strict;

use Getopt::Std;

use CXGN::Phenome::Locus;
use CXGN::Phenome::Individual;
use CXGN::Chado::Organism;

use CXGN::DB::InsertDBH;
use CXGN::Chado::Dbxref;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Ontology;
use CXGN::Chado::Relationship;

our ($opt_H, $opt_D, $opt_v, $opt_o, $opt_d, $opt_t);

#getopts('F:d:H:o:n:vD:t');
getopts('H:o:d:vD:t');
my $dbhost = $opt_H;
my $dbname = $opt_D;

if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }

my $error = 0; # keep track of input errors (in command line switches).
if (!$opt_D) { 
    print STDERR "Option -D required. Must be a valid database name.\n";
    $error=1;
}


  
my $file = $opt_o;

if (!$file) { 
    print STDERR "A file is required as a command line argument.\n";
    $error=1;
}


die "Some required command lines parameters not set. Aborting.\n" if $error;


open (OUT, ">$opt_o") ||die "can't open error file $file for writting.\n" ;


my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				     dbname=>$dbname,  
				   } );


print STDERR "Connected to database $dbname on host $dbhost.\n";
my @locus_annot= CXGN::Phenome::Locus->get_annotations_by_db($dbh, $opt_d);

my $count=0;
my $u_count =0;
print STDERR "Reading annotations from database..\n";

eval {
    foreach my $annot(@locus_annot)  {
	
	my $locus_id= $annot->get_locus_id();
	print STDERR "locus_id = $locus_id\n";
	print STDERR "." if !$opt_v;
	my $locus= CXGN::Phenome::Locus->new($dbh,$locus_id);
	my $locus_name = $locus->get_locus_name();
	my $dbxref=CXGN::Chado::Dbxref->new($dbh, $annot->get_dbxref_id);

	my $cvterm = $dbxref->get_cvterm();
	my $cvterm_name=$cvterm->get_cvterm_name();
	my $accession = $dbxref->get_accession();
	my $is_obsolete= $cvterm->get_obsolete();
	my @alt_ids = $cvterm->get_alt_id();	
	print STDERR "alt_ids = @alt_ids\n\n";
	
	if ($is_obsolete) {
	    $count++;
	    print STDERR "Locus $locus_name (id=$locus_id) has obsolete annotation: $accession:$cvterm_name\n";
	    print OUT "Locus $locus_name (id=$locus_id) has obsolete annotation: $accession:$cvterm_name\n";
	    
	    if (@alt_ids) {
		$u_count++;
		$annot->update_annotation($alt_ids[0]);
		print STDERR "*Updated annotation to $alt_ids[0]!\n";
		print OUT "*Updated annotation to $alt_ids[0]\n";
	    }else {
		print STDERR "!did not find alternative cvterm for this obsolete annotation! $cvterm_name\n";
		print OUT "!did not find alternative cvterm for this obsolete annotation! $cvterm_name\n";
	    }
	}
	
    }
    
    print STDERR "Found $count obsolete annotations for SGN loci, $u_count annotations were updated.\n printed out file $file... Done.\n";
    
    my @pheno_annot= CXGN::Phenome::Individual->get_annotations_by_db($dbh, $opt_d);
    
    $count= 0;
    $u_count=0;
    print STDERR "Reading annotations from SGN individual database..\n";
    foreach my $annot(@pheno_annot) {
	
	print STDERR "." if !$opt_v;
	my $ind_id= $annot->get_individual_id();
	my $ind= CXGN::Phenome::Individual->new($dbh,$ind_id);
	my $ind_name=$ind->get_name();
	my $dbxref=CXGN::Chado::Dbxref->new($dbh, $annot->get_dbxref_id());
	my $cvterm=$dbxref->get_cvterm();
	my $cvterm_name=$cvterm->get_cvterm_name();
	my $accession = $dbxref->get_accession();
	my $is_obsolete=$cvterm->get_obsolete();
	my @alt_ids = $cvterm->get_alt_id();
	
	if ($is_obsolete) {
	    $count++;
	    print STDERR "Individual $ind_name (id=$ind_id) has obsolete annotation: $accession:$cvterm_name\n";
	    print STDERR "Individual $ind_name (id=$ind_id) has obsolete annotation: $accession:$cvterm_name\n";
	    if (@alt_ids) {
		$u_count++;
		$annot->update_annotation($alt_ids[0]);
		print STDERR "*Updated annotation to $alt_ids[0]!\n";
		print OUT "*Updated annotation to $alt_ids[0]\n";
	    }else {
		print STDERR "!did not find alternative cvterm for this obsolete annotation! $cvterm_name\n";
		print OUT "!did not find alternative cvterm for this obsolete annotation! $cvterm_name\n";
	    }
	}
    } 
};
if ($@ || ($opt_t)) { 
    print STDERR "Either running as trial mode (-t) or AN ERROR OCCURRED: $@\n"; 
    print OUT "Either running as trial mode (-t) or AN ERROR OCCURRED: $@\n" if $opt_o; 
    
    $dbh->rollback();
    exit(0);
}
else {  $dbh->commit(); }


close OUT;

print STDERR "Found $count obsolete annotations for SGN individuals, $u_count annotations were updated.\n printed into out file $file... Done.\n";



