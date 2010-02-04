=pod

=head1 
load_match_unigenes.pl


=head2


Script for reading the output of a parsed blastout file (see sgn-tools/utils/parseblast.pl)
(originally written for BLASTing genbank sequences against SGN unigenes) 
and loading the best matches into phenome.locus_unigene table. 

The GenBank entries should be preloaded into public.dbxref before running this script



Usage: perl load_match_unigenes.pl -D dbname -H dbhost -i  infile -u [sgn user name | -p sp_person_id] -t [test mode] 

=over 6

=item -D 
db name

=item -H 
host name

=item -i
infile (a blastout file of genbank sequences against SGN Unigenes
All errors will be written to file $infile.err

=item -u  or -p
SGN user name  or sgn_people sp_person_id

=item -v
verbose output

=item -t 
trail mode. Rolling back transaction at end of script

=back 


=cut



#!/usr/bin/perl
use strict;

use CXGN::Chado::Db;
use CXGN::Chado::Dbxref;
use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusDbxref;
use CXGN::DB::InsertDBH;
use CXGN::People::Person;


use Getopt::Std;


our ($opt_H, $opt_D, $opt_v, $opt_u, $opt_i, $opt_t, $opt_p);

getopts('H:D:i:p:vtu:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $infile = $opt_i;
my $sp_person=$opt_u;
my $sp_person_id = $opt_p || "329";
my $help;

if (!$dbhost && !$dbname) { 
    print  STDERR "Need -D dbname and -H hostname arguments.\n"; 
    exit();
}
if ($opt_t) { 
    print STDERR "Trial mode - rolling back all changes at the end.\n";
}

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
                                      dbschema => 'phenome', 
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				  }
				    );

$dbh->add_search_path(qw/public utils tsearch2 phenome /);

print STDERR "Connected to database $dbname on host $dbhost.\n";

if ($opt_u) {  $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $sp_person) };

if (!$sp_person_id) {
    print STDERR "ERROR: Invalid SGN username in option -u : \"$sp_person\"!! \n";
    exit;
}

#########################################################################
my $db = CXGN::Chado::Db->new_with_name($dbh, "DB:GenBank_GI");

open (INFILE, "<$infile") || die "can't open file";   #stVSsgn.blastout out file of parseblast.pl
open (ERR, ">$infile.err") || die "Can't open the error ($infile.err) file for writing.\n";
my $dbxref_count;
my $unigene_count;
my @missing_gis;

eval {
    while (my $line = <INFILE>) {   
	chomp $line;
	my @fields = split "\t", $line;
	
	my $query_line = $fields[0];
	my (undef, $gi, undef, $version) = split '\|', $query_line;       #gi|118490014|gb|EF091878.1|
	my $hit = $fields[1];
	my $unigene_id = substr $hit, 5; #remove prefix SGN-U
	my $identity = $fields[2];
	my $evalue= $fields[10];
	
	my $dbxref=CXGN::Chado::Dbxref->new_with_accession($dbh, $gi, $db->get_db_id() );
	my $locus= CXGN::Phenome::LocusDbxref->get_locus_by_dbxref($dbh, $dbxref);
	my $locus_id= $locus->get_locus_id();
	
	if ($locus_id) {
	    if (($evalue<10E-100) && ($identity>98)) { 
		my $locus_unigene_id=$locus->get_locus_unigene_id($unigene_id);
		if (!$locus_unigene_id) {
		    $locus->add_unigene($unigene_id, $sp_person_id);
		    message("Inserting SGN-unigene $unigene_id locus: $locus_id\n");
		    $unigene_count++;
		} else {print "unigene $unigene_id already associated with locus $locus_id\n"; }
	    }else { message("skipping $gi\t $hit\t $identity\t $evalue\n"); }
	    
	}elsif(!$locus_id) { 
	    message("no locus associated with GenBank id $gi\n");
	    unless (grep(/$gi/, @missing_gis)) { push @missing_gis, $gi; }
	}else { next(); } 
    }
};   

foreach my $gi(@missing_gis) { message("$gi is not associated with an SGN locus\n"); }
if($@) {
    print $@;
    print"Failed; rolling back.\n";
    $dbh->rollback();
}else{ 
    print"Succeeded.\n";
    print "inserted $unigene_count locus - unigene associations\n";
    print scalar(@missing_gis)." GenBank entries are not associated with SGN loci. See .err file for list\n";
    if(!$opt_t) {
        print "committing .\n";
	$dbh->commit();
    }else{
	print "Running trial mode- Rolling back!\n ";
        $dbh->rollback();
    }
}

close ERR;
close INFILE;

sub message {
    my $message=shift;
    print ERR $message;
    if ($opt_v) { print STDERR $message  ; }
    #else { print STDERR "." ; }
}
