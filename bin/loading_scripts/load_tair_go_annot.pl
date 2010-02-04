 
=head1
load_tair_go_annot.pl

=head1 SYNOPSIS

    $load_tair_go_annot.pl [dbhost] [dbname] [COMMIT/ROLLBACK] -b [blastout] -a [annotations] [options]

=head1 COMMAND-LINE OPTIONS

 -b  The file containing parsed BLAST output (sol specie VS Arabidopsis)
 -a  The file containing ontology annotations of loci from the database used for running the BLAST  (TAIR)  
 -o  Ontology name. Same as name in chado.db table (GO, PO ..)


=head2 DESCRIPTION

This is a script for loading TAIR ontology annotations into phenome schema.
Reads 2 files from these options: 
1. -b BLAST output file with gi # and best hit ID (TAIR locus ID) 
2. -a GO annotations of the TAIR loci IDs

Then this script: 
- builds a hash of arrays from the GO annotation file, 
- connects to the phenome schema to get the locus id according to its GenBank annotation 
each gi# (a dbxref_key of type DB:GenBank_GI) should be related to only one locus. If 2 loci are associated to the same gi#, then they should be merged into one locus entry)
-inserts for every locus_id dbxref_id (GO accession/s from the hash of TAIR_ids => \@GO_annotations) 

=head2  USAGE 

 $perl insert_tair_go_annot.pl [dbhost] [dbname] [COMMIT/ROLLBACK] -b [parsed_blast_file] -a [imported_tair_go_file] -o [ontology name] -v [verbose output, optional]

errors are printed into $annotation_file.err


Many gi numbers from the BLAST file will not be found in the phenome database.
Some GO ids may not be avaiable in pubsearchdb (GO update file should be loaded into pubsearchdb).
Whenever sequence annotations in phenome db are updated, or new loci are entered, this script should run again.
The BLAST output file and the TAIR annotation file should also be updated periodically to synchronize our database
with new sequences sumbitted to NCBI and with new annotations that may be available in TAIR.

=head2 AUTHOR

Naama Menda (nm249@cornell.edu)
 
=cut

#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
use Getopt::Long; 
use CXGN::DB::InsertDBH;
use CXGN::Chado::Ontology;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Db;
use CXGN::Chado::Dbxref;
use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusDbxref;
#phenome schema:

CXGN::DB::Connection->verbose(0);

my ($blast_file, $annot_file, $ontology, $sp_person);
our $opt_v;

GetOptions(
	   'b|blastfile=s' =>\$blast_file,
	   'a|annotfile=s' =>\$annot_file,
	   'o|ontology=s' =>\$ontology,
	   'v'           =>\$opt_v,
           'u|user=s'     =>\$sp_person, ) or ( system( 'pod2text', $0 ), exit -1 );

unless($ARGV[0] ){die"First argument must be valid database host";}
unless($ARGV[1] eq 'sandbox' or $ARGV[1] eq 'cxgn' or $ARGV[1] eq 'cxgn_tmp'){die"Second argument must be valid database name";}
unless($ARGV[2] eq 'COMMIT' or $ARGV[2] eq 'ROLLBACK'){die'Third argument must be either COMMIT or ROLLBACK';}

unless($ontology eq 'GO' or $ontology eq 'PO'){die'-o option must be either "GO" or "PO"';} 
my $dbhost= $ARGV[0];
my $dbname= $ARGV[1];

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
                                      dbschema => 'phenome', 
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				  }
				    );

$dbh->add_search_path(qw/public utils tsearch2 phenome /);


if (!$sp_person) { $sp_person= 'nm249'; }
my $sp_person_sth=$dbh->prepare("SELECT sp_person_id FROM sgn_people.sp_person WHERE username ilike ?");
$sp_person_sth->execute($sp_person);
my ($sp_person_id)= $sp_person_sth->fetchrow_array();

if (!$sp_person_id) {
    print STDERR "ERROR: Invalid SGN username \"$sp_person\"!! \n";
    exit;
}

my $db = CXGN::Chado::Db->new_with_name($dbh, $ontology);


#query for retrieving locus_id and dbxref_id of genbank gis. Every GI# should have only one associated locus 
my $locus_gi_query= $dbh->prepare("SELECT accession, locus_id FROM phenome.locus_dbxref 
                                   JOIN locus USING (locus_id)
                                   JOIN public.dbxref USING(dbxref_id)
                                   JOIN public.db USING(db_id) WHERE db.name = 'DB:GenBank_GI' 
                                   AND locus.obsolete='f' AND locus_dbxref.obsolete='f'");
$locus_gi_query->execute();
my %gi2locus=();
while (my ($gi,$locus_id) = $locus_gi_query->fetchrow_array() ) { $gi2locus{$gi}= $locus_id; }

my $locus_go_query= $dbh->prepare("SELECT locus_id, accession FROM phenome.locus_dbxref
                                   JOIN locus USING (locus_id)
                                   JOIN public.dbxref USING(dbxref_id)
                                   JOIN public.db USING(db_id) WHERE db.name ilike ?
                                   AND locus.obsolete='f' AND locus_dbxref.obsolete='f' ");
$locus_go_query->execute($ontology);
my %locus2go=();
while (my ($locus_id, $go) = $locus_go_query->fetchrow_array() ) { push @{ $locus2go{$locus_id} }, $go; }


my $annot_count = 0;
my $exist_count= 0;
my $gene_count=0;
my $go_count=0;
my $missing_go_count=0;
my $locus_count=0;
my $go_term;

my $count;
my @annotations;
my $blast_tair_count;
my @loci;
my $old_annotation_count=0;
#open error file 
my $err_file = $annot_file . '.err';
open (ERR, ">$err_file") || die "Can't open error file for writing.\n";

eval {
    #open the BLAST result file
    # ~/solgenes/tomato/tomatoVSath.txt  
    my $blast_res= open (my $blast_res, $blast_file) || die "cannot open \"$blast_file\": $!";
    
    #skip the first line
    #<$blast_res>;
    
    #open the GO annotation file
     #~/solgenes/tomato/ATGOannot.txt , ~/scripts/pubsearch/TAIRgrow-060505.txt
    my $go_annot = open (my $go_annot, $annot_file) || die "cannot open \"$annot_file\": $!";
    #<$go_annot>; #skip    
    my %GOannot=(); # hash of arrays of GO IDs. Key=tair locus ID value= array of GO IDs
    while (my $at_line=<$go_annot>) {
	chomp $at_line;
	my @go_fields = split "\t", $at_line;
	my $tair_locus = $go_fields[0];
	my $go_acc = $go_fields[4]; #this can be a PO accession
	$go_acc= substr $go_acc, 3; 
	if ($ontology eq 'PO') {$tair_locus = $go_fields[10]; } #this is the TAIR locus ID from the PO annot. files
	$tair_locus =~ s /(.*)(AT\dG\d{5})(.*)/$2/;
	
	
	if ($tair_locus =~  m/AT.G\d{5}/ ) {
	    my $exists = grep(/$go_acc/, @{ $GOannot{$tair_locus} } );
	    if (!$exists) {
		#print "$tair_locus\t$go_acc\n";
		push @{ $GOannot{$tair_locus} }, $go_acc; #check if the go_acc is already in the array!
		push @annotations, $go_acc;
	    }
        }else { print ERR "$tair_locus is not a TAIR locus ID ?\n"; }
    } 
    print STDERR "**done reading TAIR annotation file\n\n";
    my @tair_loci=  keys %GOannot;
    print STDERR scalar@tair_loci." TAIR loci matching ". scalar@annotations. " $ontology annotations\n";
    
    my @uniq_go;
    my  %seen = ();
    foreach my $an(@annotations) {
	push(@uniq_go, $an) unless $seen{$an}++;
    }
   
    while (my $line=<$blast_res>) {

        chomp $line;
	my @fields = split "\t", $line;
	
	#print "@fields\n";
	my $genbank= $fields[0];
	my $blast_tair= $fields[1];
	#gi|68300843|gb|DQ020654.1|
	my @genbank_arr = split(/\|/, $genbank);
	my $gi = $genbank_arr[1];
	  #AT1G63020.1
	$blast_tair = substr $blast_tair , 0, 9;
	
	my $evalue= $fields[10];
	if ($evalue<(10E-20) && $GOannot{$blast_tair} ) {
	    my $locus_id = $gi2locus{$gi};
	    my $locus=CXGN::Phenome::Locus->new($dbh, $locus_id);
	    if (!$locus_id) {
		$gene_count++;
		message ("**GI $gi is not associated to an SGN locus!!\n"); 
		foreach my $go (@ { $GOannot{$blast_tair} } ) {  $missing_go_count++; }
	    }elsif ($locus_id) {
		foreach my $go ( @{ $GOannot{$blast_tair} }) {
		    my $dbxref=CXGN::Chado::Dbxref->new_with_accession($dbh, $go, $db->get_db_id() );
		    my $go_id = $dbxref->get_dbxref_id();
		    if ($go_id) {
			#check if the locus + go_annotation ID exist in locus_dbxref table
			if (grep (/$go/, @ {$locus2go{$locus_id} }) ) { $old_annotation_count ++; }
			my $duplicate_annot= CXGN::Phenome::LocusDbxref::locus_dbxref_exists($dbh, $locus_id, $go_id);
			if ($duplicate_annot) { 
			    message ("exists in locus_dbxref: locus $locus_id GO id $go_id: $go \n");
			    $exist_count++;
			}else {
			    unless (grep /^$locus_id$/, @loci) { push @loci, $locus_id ; }
			    #print STDERR "locus_id= $locus_id, gi=$gi, go_id = $go_id\n";
			    $annot_count++;
			    my $locus_dbxref_id = $locus->add_locus_dbxref($dbxref, undef, $sp_person_id);
			    message("inserting annotation  $annot_count: locus $locus_id $ontology:$go\n");
			    print STDERR "." if (!$opt_v) ;  
                            #now store the evidence :
			    
			    my $evidence=CXGN::Phenome::Locus::LocusDbxrefEvidence->new($dbh);
			    $evidence->set_locus_dbxref_id($locus_dbxref_id);
			    $evidence->set_sp_person_id($sp_person_id);
			    my $ev_cv=CXGN::Chado::Ontology->new_with_name($dbh, 'evidence_code');
			    my $ev_name='inferred from electronic annotation';
			    my $ev_code= CXGN::Chado::Cvterm->new_with_term_name($dbh,$ev_name, $ev_cv->get_cv_id() );
			    $evidence->set_evidence_code_id($ev_code->get_dbxref_id());
			    my $rel_cv=CXGN::Chado::Ontology->new_with_name($dbh, 'relationship');
			    my $rel_name = relationship($dbxref->get_cv_name() );
			    my $rel_type=CXGN::Chado::Cvterm->new_with_term_name($dbh,$rel_name, $rel_cv->get_cv_id() );
			    $evidence->set_relationship_type_id($rel_type->get_dbxref_id() );
			    my $ref_id = CXGN::Chado::Dbxref::get_dbxref_id_by_accession($dbh,'sgn_curator', 'SGN_ref');
			    $evidence->set_reference_id($ref_id);
			    my $evidence_id= $evidence->store();
			}
		    }elsif (!$go_id) { # if this GO id is not in public.dbxref
			$go_count++;
			$go_term .= $go_count."\)".$go."(gb=$genbank, tair=$blast_tair)\n";
		    }
		} 
	    }
	}
    }
};


if ($@)  {
    warn "rolling back: $@\n";
    $dbh->rollback;
}else{ 
    print"Succeeded.\n";
    print "inserted $annot_count new annotations for ". scalar@loci." loci\n";
    print "$old_annotation_count annotations already exist in table locus_dbxref. $exist_count duplicate annotations found .\n";
    print "$gene_count genes do not exist in phenome.locus. These correspond to $missing_go_count annotations\n";
    print "$go_count $ontology terms do not exist in pub_term.\n$go_term\n";
    
    print STDERR "See $err_file for detailed info\n";
    if($ARGV[2] eq 'COMMIT') {
        print STDERR "committing!\n";
	$dbh->commit();
    }else{
	print STDERR "Rolling back!\n";
        $dbh->rollback();
    }
}

close ERR;

sub relationship {
    my $cv_name = shift;
    my %rel = ("plant_growth_and_development_stage" => "assayed_during",
	       "molecular_function" => "functions_as",
	       "plant_structure" => "assayed_in",
	       "cellular_component" =>"located_in",
	       "biological_process" => "involved_in"
	       );
    my $rel_name = $rel{$cv_name};
    #print STDERR "\n*relationship type for '$cv_name' is '$rel_name' ! \n";
    return $rel_name || undef;
}

sub message {
    my $message=shift;
    print ERR $message;
    print STDERR $message if ($opt_v) ;
}

