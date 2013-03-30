
=head1

load_cassava_clone_names.pl

=head1 SYNOPSIS

    $load_cassava_clone_names.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

Updated script for loading and adding cassava clone names and synonyms.
The owners of the stock accession are not stored in stockprop, but in phenome.stock_owner.

Naama Menda (nm249@cornell.edu)

    April 2013

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

#new spreadsheet, skip 2 first columns
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);

##############
##parse first the file with the clone names and synonyms. Load is into stock, and stockprop
#############
# population for grouping the clones

my $population_name = 'Cassava clones';

my $species = 'Manihot esculenta'; #

my $sp_person_id = CXGN::People::Person->get_person_by_username($dbh, 'pkulakow'); #add person id as an option.
die "Need to have a user pre-loaded in cassavabase! " if !$sp_person_id;

my $organism = $schema->resultset("Organism::Organism")->find_or_create( {
    species => $species } );
my $organism_id = $organism->organism_id();

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
        'me.name'        => $population_name,
        'me.name'        => $population_name,
        'me.organism_id' => $organism_id,
        'type.name'      => 'population',
    },
    { join => 'type' }
    );

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
## For the stock module
################################

print "parsing spreadsheet... \n";
my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

#Contributing Organization	Official IITA Clone Name	IITA prefix	Three letter Location code	notation	Preferred cassavabase clone name	synonym1_oldclonename	synonym2	synonym3	synonym4	synonym5	error synonym1	error synonym2	error synonym3	error synonym4	error synonym5	icass	icass corrected

#11		IITA	IITA-TMS-BI090563-1	IITA-TMS	IBA		TMS-BI090563-1	BI09/0563-1

my $count;

my $coderef= sub  {
    foreach my $num (@rows ) {
	my $accession = $spreadsheet->value_at($num, 'Preferred cassavabase clone name');
	print "Cassava clone name is '" . $accession . "'\n";
        my $organization = $spreadsheet->value_at($num, 'Contributing Organization');
        my $location_code = $spreadsheet->value_at($num, 'Three letter Location code');

        my $iita_clone_name = $spreadsheet->value_at($num, "Official IITA Clone Name");
        my $syn1 =  $spreadsheet->value_at($num, "synonym1_oldclonename");
        my $syn2 =  $spreadsheet->value_at($num, "synonym2");
        my $syn3 =  $spreadsheet->value_at($num, "synonym3");
        my $syn4 =  $spreadsheet->value_at($num, "synonym4");
        my $syn5 =  $spreadsheet->value_at($num, "synonym5");
        my $icass  =  $spreadsheet->value_at($num, "icass");

        # see if a stock exists with any of the synonyms
        my @stocks = $schema->resultset("Stock:Stock")->search( {
            -or => [
                 name => $accession,
                 name => $iita_clone_name,
                 name => $syn1,
                 name => $syn2,
                 name => $syn3,
                 name => $syn4,
                 name => $syn5,
                 name => $icass,
                ], }, );
        foreach my $s(@stocks) {
            print "Looking at accession $accession, Found stock '" . $s . "'\n";
        }
        if (!@stocks) { 
            print "NEW stock: $accession";
            $count++;
        }

	#my $stock = $schema->resultset("Stock::Stock")->find_or_create(
	#    { organism_id => $organism_id,
	#      name  => $accession,
	#      uniquename => $accession,
	#      type_id => $accession_cvterm->cvterm_id(),
        #      #description => '',
	#    });
        #my $stock_id = $stock->stock_id;
        #print "Adding owner $sp_person_id \n";
	##add the owner for this stock
        #$phenome_schema->resultset("StockOwner")->find_or_create(
        #    {
        #        stock_id     => $stock->stock_id,
        #        sp_person_id => $sp_person_id,
        #    });
        #####################
	############################$stock->create_stockprops( { 'solcap number' => $sct }, { autocreate => 1 } );

	#the stock belongs to the population:
        #add new stock_relationship

	#$population->find_or_create_related('stock_relationship_objects', {
	#    type_id => $member_of->cvterm_id(),
	 #   subject_id => $stock->stock_id(),
	#} );
        print "Adding synonyms #\n";
        my @synonyms = ();
        foreach my $syn (@synonyms) {
	    if ($syn && defined($syn) ) {
		#my $existing_synonym = $stock->search_related(
                #    'stockprops' , {
                #        'me.value'   => $s,
                #        'type.name'  => 'synonym'
                #    },
                #    { join =>  'type' }
                #    )->single;
                #if (!$existing_synonym) {
                    print STDOUT "Adding synonym: $syn \n"  ;
                    #add the synonym as a stockprop
                #    $stock->create_stockprops({ synonym => $s},
                #                              {autocreate => 1,
                #                               cv_name => 'null',
                #                               allow_duplicate_values=> 1
                #                              });
                #}
            }
        }
	##$stock->create_stockprops( { variety => $var_type }, { autocreate => 1 } );

        ########
	#my @props = $stock->search_related('stockprops');
	#foreach  my $p ( @props )  {
	#    print "**the prop value for stock " . $stock->name() . " is   " . $p->value() . "\n"  if $p;
	#}
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
