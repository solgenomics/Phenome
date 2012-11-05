
=head1

load_tgrc_wild_acc.pl

=head1 SYNOPSIS

    $load_tgrc_wild_acc.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

Script for loading TGRC wild accession. Most of the LA numbers are new. but some already exist in SGN from solcap and other resources.

Naama Menda (nm249@cornell.edu)

    November 2012

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;

use CXGN::Phenome::Schema;
use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;

use CXGN::People::Person;

use Try::Tiny;

our ($opt_H, $opt_D, $opt_i, $opt_t);

getopts('H:i:tD:');

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

my %seq  = (
	    'db_db_id_seq' => $last_db_id,
	    'dbxref_dbxref_id_seq' => $last_dbxref_id,
	    'cv_cv_id_seq' => $last_cv_id,
	    'cvterm_cvterm_id_seq' => $last_cvterm_id,
	    'stock_stock_id_seq' => $last_stock_id,
	    'stockprop_stockprop_id_seq' => $last_stockprop_id,
	    'stock_relationship_stock_relationship_id_seq' => $last_stockrel_id,
	    'organism_organism_id_seq' => $last_organism_id,
	    );

#new spreadsheet
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);

##############
##parse first the file with the accessions . Load it into public.stock
#############


my $population_name = 'TGRC wild accessions';
my $common_name= 'Tomato';

my $common_name_id = 1; # find by name = $common_name !
my $species = 'any'; # this population can have members of any tomato wild species

my $sp_person_id = CXGN::People::Person->get_person_by_username($dbh, 'chetelat');
die "Need to have a user pre-loaded in the sgn database! " if !$sp_person_id;

my $organism = $schema->resultset("Organism::Organism")->find_or_create( {
    species => $species } );
my $population_organism_id = $organism->organism_id();

my $stock_rs = $schema->resultset("Stock::Stock");


#the cvterm for the population
print "Finding/creating cvterm for population\n";
my $population_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'population',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'population',
    });


my $population = $stock_rs->find_or_create(
    {
        name        => $population_name,
        uniquename  => $population_name,
        organism_id => $population_organism_id,
        type_id     => $population_cvterm->cvterm_id
    }    );

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

#db for tgrc
my $db_name = 'TGRC_accession';
my $url_prefix  = 'http://';
my $url = 'tgrc.ucdavis.edu/Data/Acc/AccDetail.aspx?AccessionNum=';

my $tgrc_db = $schema->resultset("General::Db")->find_or_create(
    { name      => $db_name,
      urlprefix => $url_prefix,
      url       => $url,
    } );
## For the stock module:
################################

print "parsing spreadsheet... \n";
my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

my $count;

my $coderef= sub  {
    foreach my $accession (@rows ) {
	print "\nlabel is $accession \n";
	my $taxon = $spreadsheet->value_at($accession, 'Taxon2 (Solanum)');
        my (undef, $s) = split(/\s/ , $taxon);
        my $species = 'Solanum ' . $s;
	print "Species = '$species'\n";

        my $collection_site = $spreadsheet->value_at($accession, 'Collection Site');
	my $state = $spreadsheet->value_at($accession, 'Province Or Department');
        my $country = $spreadsheet->value_at($accession, 'Country');

        my $var_type = "Wild";
        my $description ;
        my $organism = $schema->resultset("Organism::Organism")->find( {
	    species => $species } );
	my $organism_id;
        if ($organism) {
            $organism_id = $organism->organism_id();
        }else {
            die "!!No organism found for organism $species! \n";
        }

	my $stock = $schema->resultset("Stock::Stock")->find_or_create(
	    { organism_id => $organism_id,
	      name  => $accession,
	      uniquename => $accession,
	      type_id => $accession_cvterm->cvterm_id(),
            });
        my $stock_id = $stock->stock_id;
        print "Adding owner $sp_person_id \n";
	#add the owner for this stock
        $phenome_schema->resultset("StockOwner")->find_or_create(
            {
                stock_id     => $stock->stock_id,
                sp_person_id => $sp_person_id,
            });
        #####################
       	#add tgrc as a stock_dbxref
        my $tgrc_dbxref = $tgrc_db->find_or_create_related('dbxrefs' , { accession => $accession } );
        $tgrc_dbxref->find_or_create_related('stock_dbxrefs', {
            stock_id => $stock_id, } );

        #create stockprops
        $stock->create_stockprops( { 'collection site' => $collection_site }, { autocreate => 1 } ) if $collection_site;
        $stock->create_stockprops( { 'variety' => $var_type }, { autocreate => 1 } ) if $var_type;
        $stock->create_stockprops( { 'country' => $country }, { autocreate => 1 } ) if $country;

        #the stock belongs to the population:
        #add new stock_relationship
	$population->find_or_create_related('stock_relationship_objects', {
	    type_id => $member_of->cvterm_id(),
	    subject_id => $stock->stock_id(),
	} );
        ########
	my @props = $stock->search_related('stockprops');
	foreach  my $p ( @props )  {
	    print "**the prop value for stock " . $stock->name() . " is   " . $p->type->name . ": " .  $p->value() . "\n"  if $p;
	}
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
