
=head1 NAME

po_annotations.pl

=head1 DESCRIPTION

Usage: perl po_annotations.pl -H dbhost -D dbname -o outfile [-vdnF]

parameters

=over 6

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

=item -o 

output file 

=back

The script looks for locus and individual plant ontology annotations in the database and prints them out in a file 
formatted as listed here : http://plantontology.org/docs/otherdocs/assoc-file-format.html
The generated file should be submitted to POC (po@plantontology.org)

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=head1 VERSION AND DATE

Version 0.1, January 2008.

=cut


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

our ($opt_H, $opt_D, $opt_v, $opt_d, $opt_n, $opt_o);

#getopts('F:d:H:o:n:vD:t');
getopts('H:o:n:d:vD:t');
my $dbhost = $opt_H;
my $dbname = $opt_D;

if (!$dbhost && !$dbname) { die "Need -D dbname and -H hostname arguments.\n"; }

my $error = 0; # keep track of input errors (in command line switches).
if (!$opt_D) { 
    print STDERR "Option -D required. Must be a valid database name.\n";
    $error=1;
}

if (!$opt_d) { $opt_d="PO"; } # the database name that Dbxrefs should refer to
print STDERR "Default for -d: $opt_d (specifies the database names for Dbxref objects)\n";


if (!$opt_n) {$opt_n = "plant_structure"; } 
print STDERR "Default for  -n $opt_n (specifies the ontology name for CV objects)\n"; 
my $aspect;
if ($opt_n eq 'plant_structure' ) {    $aspect = "A";}
elsif ($opt_n eq 'plant_growth_and_development_stage') { $aspect = "G"; }

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
my @locus_annot= CXGN::Phenome::Locus->get_locus_annotations($dbh, $opt_n);

my ($count, $count_ev)= (0 x 2);
print STDERR "Reading annotations from database..\n";
foreach my $annot(@locus_annot) {
    $count++;
    print STDERR "." if !$opt_v;
    my $locus= CXGN::Phenome::Locus->new($dbh,$annot->get_locus_id);
    my $dbxref=CXGN::Chado::Dbxref->new($dbh, $annot->get_dbxref_id);
    my $dbxref_ev= $annot->get_locus_dbxref_evidence();
    
    my $object_id= $locus->get_locus_id();
    my $symbol = $locus->get_locus_symbol();
    my $ontology_id= $opt_d. ":" . $dbxref->get_accession();
    my $ref_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_reference_id() );
   
    my $ev_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_evidence_code_id() );
    my $r_synonyms= $ev_object->get_cvterm()->get_synonyms();
    my @synonyms=@$r_synonyms;
    my $ev_code= $synonyms[1];

    #skip if no evidence code provided or if inferred from electronic annotation
    if (!$ev_code || $ev_code eq 'IEA') { 
	next ;
	print STDERR "no evidence code or electronic annotation. Skipping...\n" if $opt_v;
    }else { print STDERR "Found annotation for locus $object_id ($symbol) $ontology_id evidence code: $ev_code\n"; }
    my $db_reference= $ref_object->get_db_name() || warn "!!!No reference found for annotation $ontology_id locus $object_id ($symbol)\n";
    if ($db_reference eq 'SGN_ref') { 
	$db_reference .= ":" . $ref_object->get_publication()->get_pub_id();
    }elsif ($db_reference) {
	$db_reference .= ":" . $ref_object->get_accession(); 
    } else { $db_reference = undef; }
    
    $count_ev++;
    my $ev_with_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_evidence_with() );
    my $ev_with_db= $ev_with_object->get_db_name();
    if ($ev_with_db eq 'DB:GenBank_GI') { $ev_with_db = "NCBI_gi:";} #the db abbreviation in PO/GO
    my $ev_with= $ev_with_db . $ev_with_object->get_accession();
    if ($ev_with eq ':') {$ev_with = undef;}
    my $object_name = $locus->get_locus_name();
    my @locus_synonyms= $locus->get_locus_aliases(); #an array of LocusSynonym objects..
    my $locus_s;
    foreach my $ls(@locus_synonyms) { 
	my $alias= $ls->get_locus_alias();
	$locus_s .=$alias ."|"; 
    }
    chop $locus_s; #remove last "|"
    
    my $object_type = "gene";
    my $organism = CXGN::Chado::Organism->new_with_common_name($dbh, $locus->get_common_name() );
    my $taxon= "taxon:" . $organism->get_genbank_taxon_id();
    my $date= $annot->get_modification_date();
    $date = $annot->get_create_date() if (!$date) ;
    if (!$date) { warn "!!!No date found for annotation $ontology_id locus $object_id ($symbol)\n" ; }
    $date = substr $date, 0, 10;
    $date =~ s/-//g;

    print OUT "SGN_gene\t$object_id\t$symbol\t\t$ontology_id\t$db_reference\t$ev_code\t$ev_with\t$aspect\t$object_name\t$locus_s\t$object_type\t$taxon\t$date\tSGN\n";
}

print STDERR "Found $count annotations for SGN loci, printed $count_ev into out file $file... Done.\n";

my @pheno_annot= CXGN::Phenome::Individual->get_individual_annotations($dbh, $opt_n);

my ($count, $count_ev)= (0 x 2);
print STDERR "Reading annotations from SGN individual database..\n";
foreach my $annot(@pheno_annot) {
    $count++;
    print STDERR "." if !$opt_v;
    my $ind= CXGN::Phenome::Individual->new($dbh,$annot->get_individual_id);
    my $dbxref=CXGN::Chado::Dbxref->new($dbh, $annot->get_dbxref_id);
    my $dbxref_ev= $annot->get_individual_dbxref_evidence();
    
    my $object_id= $ind->get_individual_id();
    my $symbol = $ind->get_name();
    my $object_name= $ind->get_description();
    my $ontology_id= $opt_d. ":" . $dbxref->get_accession();
    my $ref_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_reference_id() );
   
    my $ev_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_evidence_code_id() );
    my $r_synonyms= $ev_object->get_cvterm()->get_synonyms();
    my @synonyms=@$r_synonyms;
    my $ev_code= $synonyms[1];

    #skip if no evidence code provided or if inferred from electronic annotation
    if (!$ev_code || $ev_code eq 'IEA') { 
	next ;
	print STDERR "no evidence code or electronic annotation. Skipping...\n" if $opt_v;
    }else { print STDERR "Found annotation for individual $object_id ($symbol) $ontology_id evidence code: $ev_code\n"; }
    my $db_reference= $ref_object->get_db_name() || warn "!!!No reference found for annotation $ontology_id individual $object_id ($symbol)\n";
    if ($db_reference eq 'SGN_ref') { 
	$db_reference .= ":" . $ref_object->get_publication()->get_pub_id();
    }elsif ($db_reference) {
	$db_reference .= ":" . $ref_object->get_accession(); 
    } else { $db_reference = undef; }
    
    $count_ev++;
    my $ev_with_object= CXGN::Chado::Dbxref->new($dbh, $dbxref_ev->get_evidence_with() );
    my $ev_with_db= $ev_with_object->get_db_name();
    if ($ev_with_db eq 'DB:GenBank_GI') { $ev_with_db = "NCBI_gi:";} #the db abbreviation in PO/GO
    my $ev_with= $ev_with_db . $ev_with_object->get_accession();
    if ($ev_with eq ':') {$ev_with = undef;}
   
    my $ind_s;
        
    my $object_type = "phenotype";
    my $organism = CXGN::Chado::Organism->new_with_common_name($dbh, $ind->get_common_name() );
    my $taxon= "taxon:" . $organism->get_genbank_taxon_id();
    my $date= $annot->get_modification_date();
    $date = $annot->get_create_date() if (!$date) ;
    if (!$date) { warn "!!!No date found for annotation $ontology_id individual $object_id ($symbol)\n" ; }
    $date = substr $date, 0, 10;
    $date =~ s/-//g;

    print OUT "SGN_phenotype\t$object_id\t$symbol\t\t$ontology_id\t$db_reference\t$ev_code\t$ev_with\t$aspect\t$object_name\t$ind_s\t$object_type\t$taxon\t$date\tSGN\n";
}

close OUT;

print STDERR "Found $count annotations for SGN individuals, printed $count_ev into out file $file... Done.\n";



