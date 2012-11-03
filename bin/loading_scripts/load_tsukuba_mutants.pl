
=head1

load_tsukuba_mutants.pl

=head1 SYNOPSIS

    $load_tsukuba_mutatns.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -p population name
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

Updated script for loading and adding Microtom mutants from Tsukuba U.


Naama Menda (nm249@cornell.edu)

    October 2012

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;

use CXGN::Phenome::Schema;
use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;

use CXGN::Chado::Dbxref;
use CXGN::Chado::Phenotype;
use CXGN::People::Person;
use Try::Tiny;

our ($opt_H, $opt_D, $opt_i, $opt_t, $opt_p);

getopts('H:i:tD:p:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 1,
						 RaiseError => 1}
				    }
    );
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] }
					  );
my $phenome_schema= CXGN::Phenome::Schema->connect( sub { $dbh->get_actual_dbh } , { on_connect_do => ['set search_path to public,phenome;'] }  );


#getting the last database ids for resetting at the end in case of rolling back
my $last_stockprop_id= $schema->resultset('Stock::Stockprop')->get_column('stockprop_id')->max;
my $last_stock_id= $schema->resultset('Stock::Stock')->get_column('stock_id')->max;
my $last_stockrel_id= $schema->resultset('Stock::StockRelationship')->get_column('stock_relationship_id')->max;
my $last_cvterm_id= $schema->resultset('Cv::Cvterm')->get_column('cvterm_id')->max;
my $last_cv_id= $schema->resultset('Cv::Cv')->get_column('cv_id')->max;
my $last_db_id= $schema->resultset('General::Db')->get_column('db_id')->max;
my $last_dbxref_id= $schema->resultset('General::Dbxref')->get_column('dbxref_id')->max;
my $last_organism_id = $schema->resultset('Organism::Organism')->get_column('organism_id')->max;
my $last_stock_dbxref_id = $schema->resultset('Stock::StockDbxref')->get_column('stock_dbxref_id')->max;
my %seq  = (
    'db_db_id_seq' => $last_db_id,
    'dbxref_dbxref_id_seq' => $last_dbxref_id,
    'cv_cv_id_seq' => $last_cv_id,
    'cvterm_cvterm_id_seq' => $last_cvterm_id,
    'stock_stock_id_seq' => $last_stock_id,
    'stockprop_stockprop_id_seq' => $last_stockprop_id,
    'stock_relationship_stock_relationship_id_seq' => $last_stockrel_id,
    'organism_organism_id_seq' => $last_organism_id,
    'stock_dbxref_stock_dbxref_id_seq'  => $last_stock_dbxref_id,
    );


my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);


# population for the tomato mutant accessions

my $population_name = $opt_p || die "**NEED A POPULATION NAME!!**\n";
my $common_name= 'Tomato';

my $common_name_id = 1; # find by name = $common_name !
my $species = 'Solanum lycopersicum'; #

my $sp_person_id = CXGN::People::Person->get_person_by_username($dbh, 'Ariizumi');
die "Need to have a user pre-loaded in the sgn database! " if !$sp_person_id;

my $organism = $schema->resultset("Organism::Organism")->find_or_create( {
    species => $species } );
my $organism_id = $organism->organism_id();

my $stock_rs = $schema->resultset("Stock::Stock");

#the cvterm for the population
print "Finding/creating cvterm for mutant population\n";
my $population_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'mutant population',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'mutant population',
    });


my $population = $stock_rs->find_or_create(
    {
        name         => $population_name,
        uniquename   => $population_name,
        organism_id  => $organism_id,
        type_id      => $population_cvterm->cvterm_id,
    } );

#the cvterm for the accession
print "Finding/creating cvtem for 'stock type' \n";
my $accession_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'accession',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'accession',
    });

#the cvterm for the relationship type
print "Finding/creating cvtem for stock relationship 'member_of' \n";

my $member_of = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'member_of',
      cv     => 'stock relationship',
      db     => 'null',
      dbxref => 'member_of',
    });

#db for TOMATOMA
my $db_name = 'TOMATOMA';
my $url_prefix  = 'http://';
my $url = 'tomatoma.nbrp.jp/strainDetailAction.do?mutantNo=';

my $tomatoma_db = $schema->resultset("General::Db")->find_or_create(
    { name      => $db_name,
      urlprefix => $url_prefix,
      url       => $url,
    } );

my $curator_pub_id;
my $curator_pub = $schema->resultset("Pub::Pub")->find(
    { title => 'curator' } );
if ($curator_pub) {
    $curator_pub_id = $curator_pub->pub_id;
} else { die "*NO pub exists for a curator! check your database . Rolling back ! \n"; }

## For the stock module:
################################

print "parsing spreadsheet... \n";
my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

my $count;

my $coderef= sub  {
    foreach my $accession (@rows ) {
	print "label is $accession \n\n";
        #Strain Id	Organization	Strain Type	Cultivation record	Sown seeds	Germinatedãseeds	Total mutant	Total harvested seed	Plant Ontology ID	Germination rate(%)	Mutation rate(%)	First flowering date	First fruit harvesting date	Flower to fruit period	Growth Stage:Phenotype	link

        #TOMJPE0018	University of Tsukuba	EMS mutagenesis lines		1	0	0	S	PO:0001002,PO:0007042	75	11.1				fruit : Fruit morphology-Other fruit morphology	http://tomatoma.nbrp.jp/strainDetailAction.do?mutantNo=582
        my $organization = $spreadsheet->value_at($accession, 'Organization');
        my $strain_type = $spreadsheet->value_at($accession, 'Strain Type');
        chop $strain_type;
        my $ontology_ids = $spreadsheet->value_at($accession, 'Plant Ontology ID');
        my @o_ids = split(',' , $ontology_ids);

        my $text_phen = $spreadsheet->value_at($accession , 'Growth Stage:Phenotype');
        my $link = $spreadsheet->value_at($accession, "link");
        my ($url, $tomatoma_acc) = split('=' , $link);
        my $tomatoma_dbxref = $tomatoma_db->find_or_create_related('dbxrefs' , {
            accession => $tomatoma_acc, } );

        my $organism = $schema->resultset("Organism::Organism")->find( {
	    species => $species } );
	my $organism_id;
        if ($organism) {
            $organism_id = $organism->organism_id();
        }else {
            warn "!!No organism found for organism $species! \n";
        }
        my $uniquename = "$organization $strain_type $accession";
	my $stock = $schema->resultset("Stock::Stock")->find_or_create(
	    { organism_id => $organism_id,
	      name  => $accession,
	      uniquename => $uniquename,
	      type_id => $accession_cvterm->cvterm_id,
              description => $text_phen
	    });
        my $stock_id = $stock->stock_id;
        my $stock_dbxref = $tomatoma_dbxref->find_or_create_related('stock_dbxrefs', {
            stock_id => $stock_id, } );

        foreach my $ontology (@o_ids) {
            #lookup the cvterm
            my ($o_db_name, $o_accession ) = split(':' , $ontology);
            print "Adding ontology id $o_db_name : $o_accession to stock $uniquename\n";
            my $o_cvterm = $schema->resultset("General::Db")->search( { 'me.name' => $o_db_name })->
                search_related('dbxrefs',  { accession => $o_accession } )->search_related('cvterm')->single;
            $o_cvterm->find_or_create_related('stock_cvterms' , {
                stock_id => $stock_id,
                pub_id   => $curator_pub_id,
                                              });
        }
        print "Adding owner $sp_person_id \n";
	#add the owner for this stock
        $phenome_schema->resultset("StockOwner")->find_or_create(
            {
                stock_id     => $stock->stock_id,
                sp_person_id => $sp_person_id,
            });
        #####################
	#the stock belongs to the population:
        #add new stock_relationship

	$population->find_or_create_related('stock_relationship_objects', {
	    type_id => $member_of->cvterm_id(),
	    subject_id => $stock->stock_id(),
                                            } );

	#########
    }
    if ($opt_t) {
        die "TEST RUN! rolling back\n";
    }
};


try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting stocks and their properties! \n\n"; }
} catch {
    # Transaction failed
    foreach my $value ( keys %seq ) {
        my $maxval= $seq{$value} || 0;
        if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
        else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};
