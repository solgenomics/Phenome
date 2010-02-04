#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use CXGN::Phenome::Locus;
use CXGN::Tools::Run;
use CXGN::BlastDB;
use CXGN::DB::InsertDBH;
use CXGN::Tools::Organism;
use CXGN::People::Person;
use CXGN::Transcript::UnigeneBuild;


=head1 NAME

rerun_loci_unigenes.pl

=head1 DESCRIPTION

Usage: perl rerun_loci_unigenes.pl -H [dbhost] -D [dbname] -o [organism] -x [taxon_name]  -u [sp_person] [-vt]


parameters

=over 8

=item -H

hostname for database [required]

=item -D

database name [required]


=item -v

verbose output

=item -u 

sp_person user name 

=item -p

sp_person_id - your database id (sgn_people.sp_person)


=item -o 

organism name

=item x

taxon name 
the name as it appears in the blastdb dir. (lycopersicon_combined)

=item -t

test run. Rollback transaction

=back


=cut 



our ($opt_H, $opt_D, $opt_v, $opt_u, $opt_o, $opt_t, $opt_x, $opt_i, $opt_c, $opt_y, $opt_p);

getopts('H:D:p:x:vo:tu:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $organism=$opt_o;
my $sp_person=$opt_u;
my $sp_person_id = $opt_p || "329";
my $tax_name= $opt_x;

if ($opt_t) { 
    print STDERR "Trial mode - rolling back all changes at the end.\n";
}
my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
                                      dbschema => 'phenome', 
                                   } );

$dbh->add_search_path(qw/public sgn /);

print STDERR "Connected to database $dbname on host $dbhost.\n";

if ($opt_u) {  $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $sp_person) };

if (!$sp_person_id) {
    print STDERR "ERROR: Invalid SGN username in option -u : \"$sp_person\"!! \n";
    exit;
}
#get all common names from locus table 
my %common_names = CXGN::Tools::Organism::get_existing_organisms($dbh, 1);

#hash for mapping blast db names for each common_name. 
#Update this hash if other blast_dbs are needed

open (ERR, ">loci_unigene.err") || die "can't open eror file for writing !\n";
my ($new_count,$e_count, $q_count, $m_count)= (0,0,0,0);


foreach my $common_name ( keys %common_names) {
    my $common_name_id = $common_names{$common_name};
    my @builds= CXGN::Transcript::UnigeneBuild::get_builds_with_common_name($dbh, 1);
    
    my $blast_db_id= $builds[0]->get_blast_db_id();
    #If the common_name is not in  %blast_db, skip to the next one
    if (!$blast_db_id) {
	message("No blast_db found for common_name $common_name.",1);
	next();
    }
    # A new BlastDB object for finding the file_basename for blasting the sequence.
    my $blast_db=CXGN::BlastDB->from_id($blast_db_id);
   
    my $loci_query = "SELECT locus_id FROM phenome.locus WHERE common_name_id=?";
    my $sth = $dbh->prepare($loci_query);
    $sth->execute($common_name_id);
    while ( my ($locus_id)=$sth->fetchrow_array() ) { 
	my $locus= CXGN::Phenome::Locus->new($dbh, $locus_id);
	#my $common_name= $locus->get_common_name();
    
	#get all associated genbank sequences
	my @locus_dbxrefs=$locus->get_dbxrefs_by_type('genbank');
	foreach my $dbxref(@locus_dbxrefs) {
	    eval {
		my $feature= $dbxref->get_feature();
		my $accession=$feature->get_uniquename();
		my $seq= $feature->get_residues();
		my $length = length($seq);#$feature->get_seqlen();
		if ($seq && (length($seq)< 20000)) {
		    $q_count++;
		    #do a blast against this database
		    open (SEQ, ">temp_seq.seq") || die "can't open file for writing temp_seq.seq";
		    print SEQ $seq;
		    CXGN::Tools::Run->run( 'blastall',
					   -m => 8,
					   -i => 'temp_seq.seq',
					   -d => $blast_db->full_file_basename,
					   -p => 'blastn',
					   -e => '1e-50',
					   -o => 'temp_locus.blast',
			);
		
		    #my $sleeper = CXGN::Tools::Run->run_async('sleep',10);
		    #$sleeper->wait;    #waits for the process to finish
		    
		    open (INFILE, "<temp_locus.blast") || die "can't open blast outfile ";  
		    
		    # parse the best match and try to load it in the database (phenome.locus_unigene)
		    
		    while (my $line = <INFILE>) {   
			
			chomp $line;
			my @fields = split "\t", $line;
			
			my $hit = $fields[1];
			my $unigene_id = substr($hit, 5); #remove prefix SGN-U
			
			my $identity = $fields[2];
			my $evalue= $fields[10];
			my $a_length=$fields[3];
			my $ratio  = $a_length/$length;
			
			if ( ($identity>95) && ($ratio>0.8)) { 
			    $m_count++;
			    my $exists=$locus->get_locus_unigene_id($unigene_id);
			    message("Locus-unigene link exists (locus_id=$locus_id, unigene_id=$unigene_id)! Locus.pm will attempt to update obsolete=f\n",1) if $exists;
			    $e_count++ if $exists;
			    $locus->add_unigene($unigene_id, $sp_person_id);
			    next() if $exists;
			    $new_count++;
			    message("Storing unigene $unigene_id for locus $locus_id. Identity=$identity, evalue=$evalue, alignment ratio=$ratio (q_length=$length, a_length=$a_length).\n",1);
			    
			}
		    }
		    close INFILE;
		    close SEQ;
		    #$sleeper->cleanup; #don't forget to clean it up, deletes tempfiles
		}
	    };
	    if ($@) {
		message("$@", 1);
		message("Failed; rolling back.\n", 1);
		$dbh->rollback();
	    }else{ 
		print"Succeeded.\n";
		
		if(!$opt_t) {
		    $dbh->commit();
		}else{
		    print  "Test mode. Rolling back!!";
		    $dbh->rollback();
		}
	    }
	}
    }
}
system("rm -f temp_seq.seq");
system("rm -f temp_locus.blast");


message("Found $q_count query sequences\n $m_count blast matches (identity>95, evalue<1e-50,qlength/alength>0.8)\n $e_count locus-unigene links exist\n $new_count new locus-unigene links were stored in the database.",1);
close ERR;

sub message {
    my $message=shift;
    my $err=shift;
    if ($opt_v) {
	print STDERR $message. "\n";
    }
    print ERR "$message \n" if $err;
}
