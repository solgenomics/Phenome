 
=head1
load_sgn_annot.pl

=head1 SYNOPSIS

    $load_sgn_annot.pl -H [dbhost] -D [dbname]  -i [input_file] [options]

=head1 COMMAND-LINE OPTIONS


 -i  The file containing ontology annotations of loci from the database
Gene Family     Gene Symbol     Locus   GenBank Accession       GO      Relationship_Type       Evidence Code   Reference       PO      Relationship_Type       Evidence Code   Reference       PO_dev  Relationship_Type       Evidence Code   Reference       SPO     Pubmed:24903607
 

=head2 DESCRIPTION

This is a script for loading SGN ontology annotations into phenome schema.
Reads an annotation file
 -i 

Then this script: 

#- builds a hash of arrays from the GO annotation file, 
#- connects to the phenome schema to get the locus id according to its GenBank annotation 
#each gi# (a dbxref_key of type DB:GenBank_GI) should be related to only one locus. If 2 loci are associated to the same gi#, then #they should be merged into one locus entry)
#-inserts for every locus_id dbxref_id (GO accession/s from the hash of TAIR_ids => \@GO_annotations) 

=head2  USAGE 

 $perl load_sgn_annot.pl -H $host -D $dbname -i $input
 
errors are printed into $annotation_file.err

=head2 AUTHOR

Naama Menda (nm249@cornell.edu)
 
=cut

#!/usr/bin/perl

use strict;
use Try::Tiny;
use Getopt::Long; 
use CXGN::DB::InsertDBH;
use Bio::Chado::Schema;
use CXGN::Tools::File::Spreadsheet;
use File::Slurp; 

use CXGN::Phenome::Schema;
use CXGN::Phenome::LocusgroupMember;

use CXGN::Chado::Ontology;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Db;
use CXGN::Chado::Dbxref;
use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusDbxref;


my ($dbhost , $dbname , $infile ,  $sp_person , $test, $verbose, $sp_person, $gf_name);

GetOptions(
	   'H|dbhost=s' =>\$dbhost,
	   'D|dbname=s' =>\$dbname,
	   'i|infile=s' =>\$infile,
	   'v'          =>\$verbose,
           't|test'     =>\$test,
           'f|family=s' =>\$gf_name, # tcp_paralogs
           'u|user=s'   =>\$sp_person, ) or ( system( 'pod2text', $0 ), exit -1 );

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
                                      dbschema => 'phenome', 
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				  }
				    );

$dbh->add_search_path(qw/public phenome /);

my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public, phenome;'] } );

my $phenome_schema= CXGN::Phenome::Schema->connect( sub { $dbh->get_actual_dbh } , { on_connect_do => ['set search_path to public,phenome;'] }  );

if (!$sp_person) { $sp_person= 'anuradha'; }
my $sp_person_sth=$dbh->prepare("SELECT sp_person_id FROM sgn_people.sp_person WHERE username ilike ?");
$sp_person_sth->execute($sp_person);
my ($sp_person_id)= $sp_person_sth->fetchrow_array();

if (!$sp_person_id) {
    print STDERR "ERROR: Invalid SGN username \"$sp_person\"!! \n";
    exit;
}


my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($infile);
my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

#open error file
my $err_file = $infile . '.err';
#write_file( $filename, {append => 1 }, "" ); 


#Gene Family     Gene Symbol     Locus   GenBank Accession       GO      Relationship_Type       Evidence Code   Reference       PO      Relationship_Type       Evidence Code   Reference       PO_dev  Relationship_Type       Evidence Code   Reference       SPO     Pubmed:24903607

my $paralog_cvterm = $schema->resultset("Cv::Cvterm")->find(
    { 
	"me.name" => "Paralog",
	"cv.name" => "Locus Relationship",
    },
    { join => 'cv' },
    );

my $locusgroup = $phenome_schema->resultset("Locusgroup")->find_or_create( 
    {
	name            => $gf_name,
	relationship_id => $paralog_cvterm->cvterm_id,
	sp_person_id    => $sp_person_id,
    });
my $locusgroup_id = $locusgroup->locusgroup_id;

my $curator_evidence = $schema->resultset("Cv::Cvterm")->find(
    {
	name => "inferred by curator", 
    });

my $coderef= sub  {
    foreach my $num (@rows ) {
        my $gene_family  = $spreadsheet->value_at($num, "Gene Family") ;
	my $gene_symbol  = $spreadsheet->value_at($num, "Gene Symbol");
	my $genome_locus = $spreadsheet->value_at($num, "Locus");
	my $genbank      = $spreadsheet->value_at($num, "GenBank Accession");
	
	#######
	my $go_string  = $spreadsheet->value_at($num, "GO");
	my $go_rel = $spreadsheet->value_at($num, "GO Relationship_Type");
	my $go_ev  = $spreadsheet->value_at($num, "GO Evidence Code");
	my $go_ref = $spreadsheet->value_at($num, "GO Reference");
	
	#######
	my $po_string = $spreadsheet->value_at($num, "PO");
	my $po_rel = $spreadsheet->value_at($num, "PO Relationship_Type");
	my $po_ev  = $spreadsheet->value_at($num, "PO Evidence Code");
	my $po_ref = $spreadsheet->value_at($num, "PO Reference");
	
	#######
	my $dev_string = $spreadsheet->value_at($num, "PO_dev");
	my $dev_rel = $spreadsheet->value_at($num, "PO_dev Relationship_Type");
	my $dev_ev  = $spreadsheet->value_at($num, "PO_dev Evidence Code");
	my $dev_ref = $spreadsheet->value_at($num, "PO_dev Reference");
	
	#######

	#Find the locus. The Solyc ID should already be in the database. 
	#Solyc Version numbers are ignored by this constructor 
	my $locus = CXGN::Phenome::Locus->new_with_locusname($dbh, $genome_locus);
	##
	#associate the genbank accession with the locus 
	######
	my $gb_feature = CXGN::Chado::Feature->new($dbh);
	$gb_feature->set_name($genbank);
	my $feature_id = $gb_feature->feature_exists();
	print "feature_id = $feature_id\n";
	if ($feature_id) {
	    $gb_feature->set_feature_id($feature_id);
	} else {
	    #store the genbank feature
	    #fix bug in EFetch first! it returns more than the sequence submitted..##fetch the sequence from genbank...
	    my $feature_fetch= CXGN::Tools::FeatureFetch->new($gb_feature);
	    $gb_feature->store();
	    print STDERR "Stored new feature from genbank $genbank\n";
	}
	#make a locus_dbxref connection:
	my $gb_dbxref =  CXGN::Chado::Dbxref->new( $dbh, $gb_feature->get_dbxref_id() );
	$locus->add_locus_dbxref( $gb_dbxref, undef, $sp_person_id );

        ###############
	#associate pubmed
	if ($go_ref) {
	    my $publication = CXGN::Chado::Publication->new($dbh);
	    $publication->set_accession($go_ref);
	    CXGN::Tools::Pubmed->new($publication);
	    
	    my $existing_publication = $publication->publication_exists();
	    if ( !$existing_publication ) {
		#publication does not exist in our database
		my $pub_id = $publication->store();
		
	    } else { #publication exists but is not associated with the object
		$publication = set_pub_id( $existing_publication );
	    }
	    my $publication_dbxref_id = $publication->get_dbxref_id();
	    my $publication_dbxref    = CXGN::Chado::Dbxref->new( $dbh, $publication_dbxref_id );
	    
	    #check if the publication is associated with the locus 
	    if ( !( $publication->is_associated_publication( "locus", $locus->get_locus_id() ) ) ) {  
		my $associated_feature = $locus->get_locus_dbxref( $publication_dbxref);
		my $locus_dbxref_id = $associated_feature->get_locus_dbxref_id();
		my $obsolete = $associated_feature->get_obsolete();

		if ($publication_dbxref_id) {
		    $locus->add_locus_dbxref($publication_dbxref, $locus_dbxref_id, $sp_person_id );
		    print STDREE "Stores locus_dbxref for publication $go_ref\n";
		}
	    }
	}
	#### associate the ontology annotations with the locus 
	process_ontology_annot($locus,$go_string, $go_rel, $go_ev, $go_ref, $sp_person_id);
	process_ontology_annot($locus,$po_string, $po_rel, $po_ev, $po_ref, $sp_person_id);
	process_ontology_annot($locus,$dev_string, $dev_rel, $dev_ev, $dev_ref, $sp_person_id);

	###create the gene network
	#$gene_family
	my $lgm=CXGN::Phenome::LocusgroupMember->new($phenome_schema);
	$lgm->set_locus_id($locus->get_locus_id );
	$lgm->set_evidence_id($curator_evidence->cvterm_id);
	$lgm->set_sp_person_id($sp_person_id);	
	my $lgm_id= $lgm->store();
    }

};

try {
    $schema->txn_do($coderef);
    if (!$test) { print "Transaction succeeded! Commiting ontology annotations! \n\n"; }
} catch {
    # Transaction failed
    #foreach my $value ( keys %seq ) {
    #    my $maxval= $seq{$value} || 0;
    #    if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
    #    else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    #}
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};

	
sub process_ontology_annot {
    my ($locus,$string, $rel_name, $ev_name, $ref, $sp_person_id ) = @_;
    my ($cv_name, $full_accession, $term) = split "--" , $string;
    my ($db_name , $accession ) = split ":" , $full_accession;

    my $dbh = $locus->get_dbh;
    my $locus_id = $locus->get_locus_id;

    my $db = CXGN::Chado::Db->new_with_name($dbh, $db_name);
    my $dbxref=CXGN::Chado::Dbxref->new_with_accession($dbh, $accession, $db->get_db_id() );
    my $ontology_cvterm_id = $dbxref->get_dbxref_id();
    if ($ontology_cvterm_id) {
	#check if the locus + go_annotation ID exist in locus_dbxref table
	my $duplicate_annot= CXGN::Phenome::LocusDbxref::locus_dbxref_exists($dbh, $locus->get_locus_id, $ontology_cvterm_id);
	if ($duplicate_annot) { 
	    print STDERR ("exists in locus_dbxref: locus $locus accession = $full_accession \n");
	}else {
	    my $locus_dbxref_id = $locus->add_locus_dbxref($dbxref, undef, $sp_person_id);
	    print STDERR "inserting annotation locus $locus_id $full_accession\n";
	    
            #now store the evidence :
	    my $evidence=CXGN::Phenome::Locus::LocusDbxrefEvidence->new($dbh);
	    $evidence->set_locus_dbxref_id($locus_dbxref_id);
	    $evidence->set_sp_person_id($sp_person_id);
	    my $ev_cv=CXGN::Chado::Ontology->new_with_name($dbh, 'evidence_code');
	    my $ev_code= CXGN::Chado::Cvterm->new_with_term_name($dbh,$ev_name, $ev_cv->get_cv_id() );
	    $evidence->set_evidence_code_id($ev_code->get_dbxref_id());
	    my $rel_cv=CXGN::Chado::Ontology->new_with_name($dbh, 'relationship');
	   
	    my $rel_type=CXGN::Chado::Cvterm->new_with_term_name($dbh,$rel_name, $rel_cv->get_cv_id() );
	    $evidence->set_relationship_type_id($rel_type->get_dbxref_id() );
	    my $ref_id = CXGN::Chado::Dbxref::get_dbxref_id_by_accession($dbh, $ref, 'PMID');
	    $evidence->set_reference_id($ref_id);
	    my $evidence_id= $evidence->store();
			}
    } elsif (!$ontology_cvterm_id)  { # if this ontology id is not in public.dbxref
	print STDERR "Cannot find ontology id $full_accession\n";
	next();
    }
} 




