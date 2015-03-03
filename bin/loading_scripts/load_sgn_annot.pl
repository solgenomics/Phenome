 
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

use CXGN::Tools::FeatureFetch;
use CXGN::Tools::Pubmed;

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
				      dbargs => {AutoCommit => 1,
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

my ($locusgroup, $locusgroup_id);

if ($gf_name)  {
    $locusgroup = $phenome_schema->resultset("Locusgroup")->find_or_create( 
	{
	    locusgroup_name => $gf_name,
	    relationship_id => $paralog_cvterm->cvterm_id,
	    sp_person_id    => $sp_person_id,
	});
    $locusgroup_id = $locusgroup->locusgroup_id;
}

my $curator_evidence = $schema->resultset("Cv::Cvterm")->find(
    {
	name => "inferred by curator", 
    });


my $coderef= sub  {
    foreach my $num (@rows ) {
	my $gene_family  = $spreadsheet->value_at($num, "Gene Family") ;
	if (!$locusgroup_id) {
	    $locusgroup = $phenome_schema->resultset("Locusgroup")->find_or_create(
		{
		    locusgroup_name => $gene_family,
		    relationship_id => $paralog_cvterm->cvterm_id,
		    sp_person_id    => $sp_person_id,
		});
	    $locusgroup_id = $locusgroup->locusgroup_id;
	}
	my $gene_symbol  = $spreadsheet->value_at($num, "Gene Symbol");
	my $genome_locus = $spreadsheet->value_at($num, "Locus");
	my $genbank      = $spreadsheet->value_at($num, "GenBank Accession");
	
	#######
	my $go_string  = $spreadsheet->value_at($num, "GO");
	my $go_rel = $spreadsheet->value_at($num, "GO Relationship_Type") || "involved_in"; 
	my $go_ev  = $spreadsheet->value_at($num, "GO Evidence Code");
	my $go_ref = $spreadsheet->value_at($num, "GO Reference");
	
	#######
	my $po_string = $spreadsheet->value_at($num, "PO");
	my $po_rel = $spreadsheet->value_at($num, "PO Relationship_Type") || "expressed_in";
	my $po_ev  = $spreadsheet->value_at($num, "PO Evidence Code");
	my $po_ref = $spreadsheet->value_at($num, "PO Reference");
	
	#######
	my $dev_string = $spreadsheet->value_at($num, "PO_dev");
	my $dev_rel = $spreadsheet->value_at($num, "PO_dev Relationship_Type") || "expressed_in" ;
	my $dev_ev  = $spreadsheet->value_at($num, "PO_dev Evidence Code");
	my $dev_ref = $spreadsheet->value_at($num, "PO_dev Reference");
	
	#######

	#Find the locus. The Solyc ID should already be in the database. 
	#Solyc Version numbers are ignored by this constructor 
	my $locus = CXGN::Phenome::Locus->new_with_locusname($dbh, $genome_locus);
	my $locus_id = $locus->get_locus_id;
	my $locus_symbol = $locus->get_locus_symbol;
	if ( $locus_symbol ne $gene_symbol) {
	    #check if the symbol already exists for a different locus
	    my $existing_locus = $phenome_schema->resultset("Locus")->find( 
		{ locus_symbol => $gene_symbol } );
	    if ( $existing_locus ) { 
		my $existing_id = $existing_locus->locus_id;
		if ( $existing_id != $locus->get_locus_id ) {
		    warn "Cannot update locus symbol $locus_symbol (id = $locus_id)  to $gene_symbol. Already exists for locus $existing_id\n";
		}
	    } else { 
		$locus->set_locus_symbol($gene_symbol);
		$locus->store();
		print "Updated locus symbol $locus_symbol to $gene_symbol \n";
	    }
	}
        ##
	#associate the genbank accession with the locus 
	######
	if ($genbank) {
	    my $gb_feature = CXGN::Chado::Feature->new($dbh);
	    $gb_feature->set_name($genbank);
	    my $feature_id = $gb_feature->feature_exists();
	    print "feature_id = $feature_id\n";
	    if ($feature_id) {
		$gb_feature->set_feature_id($feature_id);
	    } else {
		print "**store the genbank feature\n";
		#fix bug in EFetch first! it returns more than the sequence submitted..##fetch the sequence from genbank...
		my $feature_fetch= CXGN::Tools::FeatureFetch->new($gb_feature);
		my $gb_name = $gb_feature->get_name;

		if ( $gb_name ) {
		    $gb_feature->store();
		    print STDERR "Stored new feature from genbank $genbank\n";
		}
	    }
	    #make a locus_dbxref connection:
	    my $gb_dbxref_id = $gb_feature->get_dbxref_id;
	    if ( $gb_dbxref_id) {
		my $gb_dbxref =  CXGN::Chado::Dbxref->new( $dbh, $gb_dbxref_id );
		$locus->add_locus_dbxref( $gb_dbxref, undef, $sp_person_id );
	    }
	}
        ###############
	#associate pubmed
	if ($go_ref) {
	    my $publication = CXGN::Chado::Publication->new($dbh);
	    $publication->set_accession($go_ref);
	    CXGN::Tools::Pubmed->new($publication);
	    
	    my $existing_publication = $publication->publication_exists();
	    if ( !$existing_publication ) {
		#publication does not exist in our database
		print STDERR "^^^^Storing new publication $go_ref\n\n";
		$publication->add_dbxref("PMID:" . $go_ref);
		my $pub_id = $publication->store();
				
	    } else { #publication exists but is not associated with the object
		$publication->set_pub_id( $existing_publication );
		print STDERR "publiction exists ! id = $existing_publication\n";
	    }
	    my $pmid_db = CXGN::Chado::Db->new_with_name($dbh, "PMID");
	    my $pub_dbxref = CXGN::Chado::Dbxref->new_with_accession($dbh, $go_ref, $pmid_db->get_db_id);
	    my $publication_dbxref_id = $pub_dbxref->get_dbxref_id();
	    my $publication_dbxref    = CXGN::Chado::Dbxref->new( $dbh, $publication_dbxref_id );
	    print STDERR "^^^##publication dbxref_id = $publication_dbxref_id\n\n";
	    #check if the publication is associated with the locus 
	    if ( !( $publication->is_associated_publication( $locus, $locus->get_locus_id() ) ) ) {  
		my $associated_feature = $locus->get_locus_dbxref( $publication_dbxref);
		my $locus_dbxref_id = $associated_feature->get_locus_dbxref_id();
		my $obsolete = $associated_feature->get_obsolete();
		print STDERR "Publication dbxref $locus_dbxref_id is not associated!!!\n\n";
		if ($publication_dbxref_id) {
		    $locus->add_locus_dbxref($publication_dbxref, $locus_dbxref_id, $sp_person_id );
		    print STDREE "Stored locus_dbxref for publication $go_ref\n";
		}
	    }
	}
	#### associate the ontology annotations with the locus 
	if ($go_string)   { process_ontology_annot($locus,$go_string, $go_rel, $go_ev, $go_ref, $sp_person_id); }
	if ( $po_string)  { process_ontology_annot($locus,$po_string, $po_rel, $po_ev, $po_ref, $sp_person_id); }
	if ( $dev_string) { process_ontology_annot($locus,$dev_string, $dev_rel, $dev_ev, $dev_ref, $sp_person_id); }

	###create the gene network
	#$gene_family
	my $lgm=CXGN::Phenome::LocusgroupMember->new($phenome_schema);
	# find if the locus already has a group of paralogs 
	my $members_rs = $phenome_schema->resultset("LocusgroupMember")->search( 
	    {
		locus_id => $locus->get_locus_id,
	    } );
	if ($members_rs ) {
	    my $paralog_group = $members_rs->search_related(
		"locusgroup_id",  { relationship_id => $paralog_cvterm->cvterm_id }  )->first;
	    if ($paralog_group) { 
		my $paralog_id = $paralog_group->locusgroup_id;
		if ( $paralog_id) { $locusgroup_id = $paralog_id; }
	    }
	}
	    
	$lgm->set_locusgroup_id($locusgroup_id);
	$lgm->set_locus_id($locus->get_locus_id );
	$lgm->set_evidence_id($curator_evidence->cvterm_id);
	$lgm->set_sp_person_id($sp_person_id);	
	my $lgm_id= $lgm->store();
    }
};
    
try {
    $schema->txn_do($coderef);
    if (!$test) { 
	print "Transaction succeeded! Commiting ontology annotations! \n\n"; 
    }
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
    print STDERR "**db_name = $db_name , accession = $accession\n";
    my $dbxref=CXGN::Chado::Dbxref->new_with_accession($dbh, $accession, $db->get_db_id() );
    my $ontology_cvterm_id = $dbxref->get_dbxref_id();
    if ($ontology_cvterm_id) {
	#check if the locus + go_annotation ID exist in locus_dbxref table
	#my $duplicate_annot= CXGN::Phenome::LocusDbxref::locus_dbxref_exists($dbh, $locus->get_locus_id, $ontology_cvterm_id);
	#if ($duplicate_annot) { 
	#    print STDERR ("exists in locus_dbxref: locus $locus_id accession = $full_accession \n");
	#}else {
	    my $locus_dbxref_id = $locus->add_locus_dbxref($dbxref, undef, $sp_person_id);
	    print STDERR "inserting annotation locus $locus_id $full_accession\n";
	    
            #now store the evidence :
	    my $evidence=CXGN::Phenome::Locus::LocusDbxrefEvidence->new($dbh);
	    $evidence->set_object_dbxref_id($locus_dbxref_id);
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
    elsif (!$ontology_cvterm_id)  { # if this ontology id is not in public.dbxref
	print STDERR "Cannot find ontology id $full_accession\n";
	next();
    }
} 




