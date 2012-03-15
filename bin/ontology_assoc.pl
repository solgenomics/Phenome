
=head1 NAME

ontology_assoc.pl

=head1 DESCRIPTION

Usage: perl ontology_assoc.pl -H dbhost -D dbname -o outfile [-vdnfgxp]

parameters

=over 11

=item -H

hostname for database [required]

=item -D

database name [required]

=item -v

verbose output

=item -d

database name for linking (must be in Db table) Default: PO

=item -n

controlled vocabulary name. Defaults to "plant_structure".

=item -x

search for secondary dbxrefs and include those terms in annotation file

=item -o

output file

=item -g

organism name [optional]

=item -f

don't skip electronic annotations

=item -p

print all result in one file (default: print seperate file for each taxon)

=item -b
print for the genes file the associated genbank accessions and SGN unigenes

=back

The script looks for locus and stock plant ontology annotations in the database and prints them out in a file
formatted as listed in the PO site
http://plantontology.org/docs/otherdocs/assoc-file-format.html

and here for GO
http://www.geneontology.org/GO.format.gaf-2_0.shtml


The generated file should be submitted to POC via svn
or GOC via cvs

see SGN internal wiki (OntologyPipeline) for access instructions

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=head1 VERSION AND DATE

Version 1.0 February 2012.

=cut


use strict;

use Getopt::Std;
use File::Slurp;

use CXGN::Phenome::Locus;

use CXGN::Chado::Organism;
use Bio::Chado::Schema;

use CXGN::DB::InsertDBH;
use CXGN::Chado::Dbxref;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Ontology;
use CXGN::Chado::Relationship;

use Carp qw /croak cluck/ ;

our ($opt_H, $opt_D, $opt_v, $opt_d, $opt_n, $opt_o, $opt_x, $opt_g, $opt_f, $opt_p, $opt_b);

getopts('H:o:n:xd:vD:bptfg');
my $dbhost = $opt_H;
my $dbname = $opt_D;

if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }

my $error = 0; # keep track of input errors (in command line switches).
if (!$opt_D) {
    print STDOUT "Option -D required. Must be a valid database name.\n";
    $error=1;
}

if (!$opt_d) { $opt_d="PO"; } # the database name that Dbxrefs should refer to
print STDOUT "Default for -d: $opt_d (specifies the database names for Dbxref objects)\n";


if (!$opt_n) {$opt_n = "plant_structure"; } 
print STDOUT "Default for  -n $opt_n (specifies the ontology name for CV objects)\n"; 
my $aspect;
my $namespace;
if ($opt_n eq 'plant_anatomy' ) {    $aspect = "A"; $namespace='anatomy';}
elsif ($opt_n eq 'plant_growth_and_development_stage') { $aspect = "G"; $namespace='growth';}
elsif ($opt_n eq 'biological_process') { $aspect = "P"; $namespace = 'P'; }
elsif ($opt_n eq 'molecular_function') {$aspect = "F"; $namespace= 'F'; }
elsif ($opt_n eq 'cellular_component') {$aspect = "C";$namespace = 'C'; }


#po_anatomy_gene_Capsicum_sgn.assoc
#po_growth_phenotype_lycopersicum_sgn.assoc

die "Some required command lines parameters not set. Aborting.\n" if $error;


my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				     dbname=>$dbname,
				   } );
my $schema= Bio::Chado::Schema->connect( sub { $dbh->get_actual_dbh() } ,
					 { on_connect_do => ['SET search_path TO public'], }, );  


our %species = (
    'Tomato' => 'Solanum lycopersicum',
    'Potato' => 'Solanum tuberosum',
    'Pepper' => 'Capsicum',
    'Eggplant' => 'Solanum melongena',
    'Petunia' => 'Petunia',
    'Physalis' => 'Physalis',
    'Tobacco' => 'Nicotiana',
    'Apple Of Sodom' => 'Solanum linnaeanum',
    'Atropa' => 'Atropa',
    'Datura' => 'Datura',
    'Henbane'=>'Hyoscyamus',
    'Anisodus' => 'Anisodus' ,
    'Morning Glory'=> 'Ipomoea nil',
    'Sweet Potato'=> 'Ipomoea batatas',
    'Hedyotis' => 'Hedyotis',
    'Coffee' => 'Coffea',
    'Snapdragon' => 'Antirrhinum'
    );
print STDOUT "Connected to database $dbname on host $dbhost.\n";
my @locus_annot= CXGN::Phenome::Locus->get_curated_annotations($dbh, $opt_n);
my @locus_xref_annot = CXGN::Phenome::Locus->get_curated_annotations($dbh, 'solanaceae_phenotype');

##############
###re-write these::
my @pheno_annot = $schema->resultset("Stock::Stock")->search_related(
    'stock_cvterms' ,
    {
        'cv.name' => $opt_n ,
    }, { join => { cvterm => 'cv' } } )->all; # list of cvterm objects
#my @pheno_annot= CXGN::Phenome::Individual->get_individual_annotations($dbh, $opt_n);
#my @pheno_xref_annot= CXGN::Phenome::Individual->get_individual_annotations($dbh, 'solanaceae_phenotype');
my @pheno_xref_annot = $schema->resultset("Stock::Stock")->search_related(
    'stock_cvterms' ,
    {
        'cv.name' => 'solanaceae_phenotype' ,
    }, { join => { cvterm => 'cv' } } )->all; # list of cvterm objects
###################

print STDOUT scalar(@locus_annot) . " locus annotations found...\n";
print STDOUT scalar(@locus_xref_annot) . " locus xref annotations found...\n";


print STDOUT "Reading locus annotations from database..\n";
our %l_annot=();
our %p_annot=();
our %gene;
our %pheno;
#print the xref annotations from cvterm_dbxref:
if ($opt_x) {   print_gene_annotations( 'xref' , @locus_xref_annot);  }
print_gene_annotations(undef, @locus_annot);



print STDOUT scalar(@pheno_annot) . " phenotype annotations found...\n";
print STDOUT scalar(@pheno_xref_annot) . " phenotype xref annotations found...\n";


print STDOUT "Reading phenotype annotations from database..\n";

#print the xref annotations from cvterm_dbxref:
if ($opt_x) {   print_pheno_annotations('xref', @pheno_xref_annot); }
print_pheno_annotations(undef, @pheno_annot);

if ($opt_p) {
    my $file = lc ($opt_d) . "_" .$namespace . "_gene_sgn.assoc" ;
    open (OUTF, ">$file") ||die "can't open  file $file for writting.\n" ;
    foreach my $taxon( keys %gene) {
	foreach (@{ $gene{$taxon }  }) {
	    print OUTF $_;
	}
    }
    close OUTF;
    my $file = lc ($opt_d) . "_" .$namespace . "_germplasm_sgn.assoc" ;
    open (OUTF, ">$file") ||die "can't open  file $file for writting.\n" ;
    foreach my $taxon( keys %pheno) {
	foreach (@{ $pheno{$taxon }  }) {
	    print OUTF $_;
	}
    }
    close OUTF;
}else {
    foreach my $taxon( keys %gene) {
	my $file = lc ($opt_d) . "_" .$namespace . "_gene_" . $taxon . "_sgn.assoc" ;
	open (OUTF, ">$file") ||die "can't open  file $file for writting.\n" ;
	#po_anatomy_gene_Capsicum_sgn.assoc
	foreach (@{ $gene{$taxon }  }) {
	    print OUTF $_;
	}
	close OUTF;
    }
    foreach my $taxon( keys %pheno) {
	my $file = lc ($opt_d) . "_" .$namespace . "_germplasm_" . $taxon . "_sgn.assoc" ;
	open (OUTF, ">$file") ||die "can't open  file $file for writting.\n" ;
	#po_anatomy_gene_Capsicum_sgn.assoc
	foreach (@{ $pheno{$taxon }  }) {
	    print OUTF $_;
	}
	close OUTF;
    }
}

sub print_gene_annotations {
    my $type=shift;
    my @locus_annot= @_;
    
    my %xref_annot; #hash of arrays for storing unique xref annotations.
   
    my $count= 0 ;
    my $count_ev=0;
    my $xref_count=0;
    my $object = "SGN_gene";
    $object = "SGN" if ($opt_d eq 'GO');
    foreach my $annot(@locus_annot) {
	$count++;
	print STDOUT "looking at gene anotation $count for locus_id ". $annot->get_locus_id() . " \n";
	my ($gb_links, $unigenes);
	my $locus= CXGN::Phenome::Locus->new($dbh,$annot->get_locus_id);
	my $dbxref=CXGN::Chado::Dbxref->new($dbh, $annot->get_dbxref_id);
	my $cv=$dbxref->get_cv_name();
	
	my $object_id= $locus->get_locus_id();
	my $symbol = $locus->get_locus_symbol();
	my $ontology_id= $dbxref->get_db_name(). ":" . $dbxref->get_accession();
	if ($opt_b) {
	    my @gb= $locus->get_dbxrefs_by_type('genbank');
	    foreach (@gb) {  $gb_links .= $_->get_feature()->get_uniquename() . "|" ;  }
	    my @un = $locus->get_unigenes();
	    foreach (@un) { $unigenes .= "SGN-U" . $_->get_unigene_id() . "|"; }
	}
	###
	my $object_name = $locus->get_locus_name();
	my @locus_synonyms= $locus->get_locus_aliases('f','f'); #an array of LocusSynonym objects..
	my $locus_s;
	foreach my $ls(@locus_synonyms) { 
	    my $alias= $ls->get_locus_alias();
	    $locus_s .=$alias ."|"; 
	}
	chop $locus_s; #remove last "|"
	
	my $object_type = "gene";
	###
	my $common_name= $locus->get_common_name();
	my $species = $species{$common_name} || croak "No species found for common name $common_name ! Check your code. \n";
	
	my $organism = CXGN::Chado::Organism->new_with_species($schema, $species);
	my $taxon= "taxon:" . $organism->get_genbank_taxon_id();
	my $org_name = $organism->get_abbreviation || $organism->get_species() ;
	###
	my $date= $annot->get_modification_date();
	$date = $annot->get_create_date() if (!$date) ;
	if (!$date) { warn "!!!No date found for annotation $ontology_id locus $object_id ($symbol)\n" ; }
	$date = substr $date, 0, 10;
	$date =~ s/-//g;
	###
	chomp $unigenes;
	chomp $gb_links;
	#print STDOUT "unigenes: $unigenes, gb_links: $gb_links \n" if $opt_v && ($unigenes || $gb_links);
	my @ev= $annot->get_locus_dbxref_evidence('f');
	my $ev_count;
	EVIDENCE: foreach my $dbxref_ev (@ev) { 
	    $ev_count++;

	    print STDOUT "...Looking at evidence $ev_count...(id = " . $dbxref_ev->get_object_dbxref_evidence_id(). ")\n" if $opt_v; 
	    my $ref_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_reference_id() );

	    my $ev_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_evidence_code_id() );

	    my @ev_synonym= $ev_object->get_cvterm()->get_synonyms(); #the synonym of an evidence-code cvterm is its abbreviation
	    #there should be just one synonym for the evidence code
	    my $ev_code= $ev_synonym[0];

	    #skip if no evidence code provided or if inferred from electronic annotation
	    if (!$ev_code || $ev_code eq 'IEA') { 
		print STDOUT "no evidence code or electronic annotation. Skipping...(ev_code_id = " . $dbxref_ev->get_evidence_code_id() . ")\n" if $opt_v;
		next EVIDENCE unless $opt_f;
	    }else { }#print STDERR "Found annotation for locus $object_id ($symbol) $ontology_id evidence code: $ev_code\n"; }
	    my $db_reference= $ref_object->get_db_name(); 
	    if ($db_reference eq 'SGN_ref') { 
		$db_reference .= ":" . $ref_object->get_publication()->get_pub_id();
	    }elsif ($db_reference) {
		$db_reference .= ":" . $ref_object->get_accession(); 
	    }else {
		#warn "!!!No reference found for annotation $ontology_id locus $object_id ($symbol)\n";
		$db_reference = 'SGN_ref:861';
	    }

	    my $ev_with_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_evidence_with() );
	    my $ev_with_db= $ev_with_object->get_db_name();
	    if ($ev_with_db eq 'DB:GenBank_GI') { $ev_with_db = "NCBI_gi:";} #the db abbreviation in PO/GO
	    my $ev_with= $ev_with_db . $ev_with_object->get_accession();
	    if ($ev_with eq ':') {$ev_with = undef;}
	    if ( $ev_code eq 'IDA') { $ev_with = undef; } 

	    if ($type eq 'xref') {
		#print STDERR "$type: getting cvterm_dbxrefs from database...\n";
		my @cv_dbxrefs=$dbxref->get_cvterm_dbxrefs();

		foreach my $cd(@cv_dbxrefs) {
		    if ( ($cd->get_cv_name() ) eq $opt_n ) {
			# print STDERR "Found xref term '" . $cd->get_db_name() .":" . $cd->get_accession() ."'\n";

			$ontology_id= $cd->get_db_name(). ":" . $cd->get_accession();
			my $test_ontology_id = $ontology_id . $ev_code;
                         #check for duplicates both in xref and in direct annotations:
			if ( (!grep /$test_ontology_id/, @{$xref_annot{$object_id}}) && (!grep /$test_ontology_id/, @{$l_annot{$object_id}}) ) {  
			    $xref_count++;
			    push @{ $xref_annot{$object_id} }, $test_ontology_id;
			    my $info= "$object\t$object_id\t$symbol\t\t$ontology_id\t$db_reference\t$ev_code\t$ev_with\t$aspect\t$object_name\t$locus_s\t$object_type\t$taxon\t$date\tSGN\t$gb_links\t$unigenes\n";
			    push @{ $gene{$org_name} } , $info;
			}
		    }
		}
	    }
	    #print STDERR "cv=$cv, opt_n=$opt_n!\n";
	    my $test_ontology_id = $ontology_id . $ev_code;
	    if ($cv eq $opt_n) {
		##print STDERR "  !! ontology_id = $test_ontology_id ! \n\n ";
		if ( !grep /$test_ontology_id/ , @{$l_annot{$object_id}} ) {  
		    $count_ev++;
		    push @{ $l_annot{$object_id} }, $test_ontology_id;
		    my $info= "$object\t$object_id\t$symbol\t\t$ontology_id\t$db_reference\t$ev_code\t$ev_with\t$aspect\t$object_name\t$locus_s\t$object_type\t$taxon\t$date\tSGN\t$gb_links\t$unigenes\n";
		    push @{ $gene{$org_name} } , $info;
		}
	    }else { warn "cv ($cv) does not match opt_n ($opt_n)\n";}
	}
    }
    print STDOUT "Found $count_ev direct and $xref_count xref annotations for SGN loci, printed into out file ... Done.\n";
}


sub print_pheno_annotations {
    my $type=shift;
    my @pheno_annot=@_; # list of StockCvterm objects
    my $count= 0 ;
    my $count_ev=0;
    my $xref_count=0;
    my %xref_annot; #hash of arrays for storing unique xref annotations.
    ANNOT: foreach my $annot(@pheno_annot) {
	$count++;
	print STDOUT "." if !$opt_v;
        my $stock = $annot->stock;
        #my $ind= CXGN::Phenome::Individual->new($dbh,$annot->get_individual_id);
	#my $dbxref=CXGN::Chado::Dbxref->new($dbh, $annot->get_dbxref_id);
	#my $cv= $dbxref->get_cv_name();
        my $dbxref = $annot->cvterm->dbxref;
	my $cv = $annot->cvterm->cv->name;
	my $object_id= $stock->stock_id;
	my $symbol = $stock->name;
	my $object_name= $stock->uniquename;
	my $ontology_id= $dbxref->db->name . ":" . $dbxref->accession;
	##
	my $stock_s; # a variable for stock synonyms. These are loaded in stockprop
        ##
	my $object_type = "germplasm";
	###
        my $species = $stock->organism->species || warn "No species for stock " . $stock->name . " ! Check your code. \n";
	next ANNOT if !$species;
	my $organism = $stock->organism;
	my $taxon= "taxon:" . $organism->organism_dbxrefs->search_related(
            'dbxref', {
                'db.name' =>'DB:NCBI_taxonomy',
                } , { join => 'db' } )->single->accession;
	my $org_name= $organism->abbreviation || $organism->species;
        my $props = $annot->stock_cvtermprops;
	###modified_date create_date##########
        my $date;
	my ($dateprop) = $props->search( { 'type.name' => 'modified_date' } , { prefetch => 'type' } );
	($dateprop) = $props->search( { 'type.name' => 'create_date' } , { prefetch => 'type' } ) if (!$dateprop) ;
	if (!$dateprop) {
            warn "!!!No date found for annotation $ontology_id stock $object_id ($symbol)\n" ; 
        } else {
            $date = $dateprop->value;
        }
	$date = substr $date, 0, 10;
	$date =~ s/-//g;
	##
        # a cvterm_id
        my ($evidence) = $props->search( { 'type.name' => 'evidence_code' } , { prefetch => 'type' } );
        # a pub id
        my $reference = $annot->pub;
        my $evidence_id = $evidence->value if $evidence;
        my $ev_object = CXGN::Chado::Cvterm->new($dbh, $evidence_id);
        #the synonym of an evidence-code cvterm is its abbreviation
        my @ev_synonym= $ev_object->get_synonyms();
        #there should be just one synonym for the evidence code
        my $ev_code= $ev_synonym[0];
        #skip if no evidence code provided or if inferred from electronic annotation
        if (!$ev_code || $ev_code eq 'IEA') {
            #print STDERR "no evidence code or electronic annotation. Skipping...\n" if $opt_v;
            next() ;
        }else {} #print STDERR "Found annotation for stock $object_id ($symbol) $ontology_id evidence code: $ev_code\n"; }
        my $db_reference= $reference->pub_dbxrefs->search_related('dbxref')->first->db->name if $reference;
        if ($db_reference eq 'SGN_ref') {
            $db_reference .= ":" . $reference->pub_id;
        }elsif ($db_reference) {
            $db_reference .= ":" . $reference->pub_dbxrefs->search_related('dbxref')->first->accession;
        } else {
            $db_reference = 'SGN_ref:861';
            # warn "!!!No reference found for annotation $ontology_id stock $object_id ($symbol)\n";
        }
        my ($ev_with_cvterm) = $props->search( {'type.name' => 'evidence_with'} , { prefetch => 'type' } );
        my $ev_with_db= $ev_with_cvterm->dbxref->db->name if $ev_with_cvterm;
        if ($ev_with_db eq 'DB:GenBank_GI') { $ev_with_db = "NCBI_gi:";} #the db abbreviation in PO/GO
        my $ev_with= $ev_with_db . $ev_with_cvterm->dbxref->accession if $ev_with_cvterm;

        if ($type eq 'xref') {
            #print STDERR "$type: getting cvterm_dbxrefs from database...\n";
            my $cv_dbxref = $annot->cvterm->search_related('cvterm_dbxrefs');
            while (my $cd = $cv_dbxref->next ) {
                if ( $cd->dbxref->cvterm ) {
                    if ( ($cd->dbxref->cvterm->cv->name ) eq $opt_n ) {
                        #print STDERR "$opt_n: Found xref term '" . $cd->get_db_name() .":" . $cd->get_accession() ."'\n";
                        #check for duplicates both in xref and in direct annotations:
                        my $ontology_id= $cd->dbxref->db->name . ":" . $cd->dbxref->accession;
                        if ( (!grep /$ontology_id/, @{$xref_annot{$object_id}}) && (!grep /$ontology_id/, @{$p_annot{$object_id}}) ) {
                            print STDERR "Found xref term '" . $cd->dbxref->db->name .":" . $cd->dbxref->accession ."'\n";
                            $xref_count++;
                            push @{ $xref_annot{$object_id} }, $ontology_id;
                            my $info= "SGN_germplasm\t$object_id\t$symbol\t\t$ontology_id\t$db_reference\t$ev_code\t$ev_with\t$aspect\t$object_name\t$stock_s\t$object_type\t$taxon\t$date\tSGN\n";
                            push @{ $pheno{$org_name} } , $info;
                        }
                    }
                }
            }
	    if ($cv eq $opt_n) {
		$count_ev++;
		if ( !grep /$ontology_id/ , @{$p_annot{$object_id}} ) {
		    push @{ $p_annot{$object_id} }, $ontology_id;
		    my $info= "SGN_germplasm\t$object_id\t$symbol\t\t$ontology_id\t$db_reference\t$ev_code\t$ev_with\t$aspect\t$object_name\t$stock_s\t$object_type\t$taxon\t$date\tSGN\n";
		    push @{ $pheno{$org_name} }, $info;
		}
	    }
        }
    }
    print STDOUT "Found $count_ev direct and $xref_count xref annotations for SGN stocks, printed into out file $opt_o... Done.\n";
}

