
=head1

load_solcap_tomato_acc.pl

=head1 SYNOPSIS

    $load_solcap_tomato_acc.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name 
 -D  database name 
 -i infile 
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION



Naama Menda (nm249@cornell.edu)

    July 2010
 
=cut


#!/usr/bin/perl
use strict;
use Getopt::Std; 
use CXGN::Tools::File::Spreadsheet;

use CXGN::Phenome::Schema;
use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;

use CXGN::Phenome::Population;
use CXGN::Phenome::Individual;
use CXGN::Chado::Dbxref;
use CXGN::Chado::Phenotype;


our ($opt_H, $opt_D, $opt_i, $opt_t);

getopts('H:i:tD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				    }
    );
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] }
					  );
my $phenome_schema= CXGN::Phenome::Schema->connect( sub { $dbh->get_actual_dbh() , { on_connect_do => ['set search_path to phenome;'] } } );


#getting the last database ids for resetting at the end in case of rolling back
my $last_cvtermprop_id= $schema->resultset('Cv::Cvtermprop')->get_column('cvtermprop_id')->max; 


#new spreadsheet, skip 2 first columns
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);

##############
##parse first the file with the accessions . Load it into phenome.individual and public.stock
#############

### sp_term scale_name value name_string
##my $scale_cv_name= "breeders scale";

# population for the tomato accessions 

my $population_name = 'Tomato Cultivars and Heirloom lines';
my $common_name= 'Tomato';

my $common_name_id = 1; # find by name = $common_name !
my $sp_person_id = undef; # who is the owner ? 


#my $population = $phenome_schema->resultset("Population")->find_or_create( 
 #   {
#	name => $population_name,
#	common_name_id => $common_name_id,
#    });
my $population = CXGN::Phenome::Population->new_with_name($dbh, $population_name);

if (!$population->get_population_id() ) { 
	$population->set_common_name_id($common_name_id);
	$population->set_name($population_name);
	$population->set_sp_person_id($sp_person_id);
	$population->store();
}

my $organism = $schema->resultset("Organism::Organism")->find( {
    species => 'Solanum lycopersicum' } );
my $organism_id = $organism->organism_id();

## For the stock module:

#the cvterm for the population
print "Finding/creating cvterm for population\n";
my $population_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'population',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'population',
    });

################################

my $stock_population = $schema->resultset("Stock::Stock")->find_or_create(
    { organism_id => $organism_id,
      name  => $population_name,
      uniquename => $population_name,
      type_id => $population_cvterm->cvterm_id(),
    } );

## for this Unit Ontology has to be loaded! 
##my $unit_cv = $schema->resultset("Cv::Cv")->find(
 ##   { name => 'unit.ontology' } );

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

eval {
    
    foreach my $sct (@rows ) { 
	print "label is $sct \n\n";
	#Tomato Germplast Passport sheet . Rows are SCT#s, which are accession synonyms.

	#my ($acc, $rep) = split (/\|/ , $accession);
	
	my $accession = $spreadsheet->value_at($sct, 'Donor number/Variety Name:');
	
	
       #the cvterm for the accession
	print "Finding/creating cvtem for 'stock type' \n"; 
	my $accession_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
	    { name   => 'accession',
	      cv     => 'stock type',
	      db     => 'null',
	      dbxref => 'accession',
	    });
	my $stock = $schema->resultset("Stock::Stock")->find_or_create( 
	    { organism_id => $organism_id,
	      name  => $accession,
	      uniquename => $accession,
	      type_id => $accession_cvterm->cvterm_id()
	    });
	    
	#the stock belongs to the population:
	
        #add new stock_relationship
	#the cvterm for the relationship type 
	print "Finding/creating cvtem for stock relationship 'is_member_of' \n"; 
	
	my $member_of = $schema->resultset("Cv::Cvterm")->create_with(
           { name   => 'is_member_of',
	     cv     => 'stock relationship',
	     db     => 'null',
	     dbxref => 'is_member_of',
	 });
	
	$stock_population->find_or_create_related('stock_relationship_subjects', {
	    type_id => $member_of->cvterm_id(),
	    object_id => $stock->stock_id(),
	} );
	
	#store the accession in the individual table 
	##############################################
        #my $individual = $phenome_schema->resultset("Individual")->find_or_create(
	#    { population_id => $population->get_population_id(),
	#     name => $accession,
	#    common_name_id => $common_name_id,
	#    sp_person_id => $sp_person_id,
	#  } );
	my @individuals= CXGN::Phenome::Individual->new_with_name($dbh, $accession, $population->get_population_id() );
	
	my $individual= $individuals[0] if @individuals;
	
	if (!@individuals) {
	    print "instantiating new individual!!!!\n";
	    $individual= CXGN::Phenome::Individual->new($dbh);
	    $individual->set_name($accession);
	    $individual->set_population_id($population->get_population_id()); 
	    $individual->set_sp_person_id($sp_person_id); 
	    $individual->set_common_name_id($common_name_id);
	    $individual->store();
	}
	
	
	my $la = $spreadsheet->value_at($sct, "Accession number LA number (if available):");
	chomp($la);
	my $pi = $spreadsheet->value_at($sct, "Accession number PI number (if available):");
	chomp($pi);
	my $syn = $spreadsheet->value_at($sct, "Synonyms:");
	chomp($syn);
	
	my @synonyms = ($la, $pi, $syn);
	
        foreach my $s (@synonyms) {
	    if ($s && defined($s) ) {
		$individual->add_individual_alias($s, $sp_person_id); 
		
		print STDOUT "Adding synonym: $s \n"  ;
		#add the synonym as a stockprop
		$stock->create_stockprops({ synonym => $s}, 
					  {autocreate => 1, 
					   cv_name => 'null'
					   });
	    }
	}
	#my @props = $stock->find_related('stockprops');
	#foreach  my $p ( @props )  {
	#    print "**the prop is $p, value = " . $p->value() . "\n"  if $p;
	#}
	
	my $var_type = $spreadsheet->value_at($sct, "Heirloom, LandRace, FreshMarket, Processing, Wild, other");

	$stock->create_stockprops( { variety => $var_type }, { autocreate => 1 } );
	
##
	my $donor = $spreadsheet->value_at($sct,"Name of Donor:");
	$stock->create_stockprops( { donor  => $var_type }, { autocreate => 1 } );
	##
	#Donor is SolCAP, and should be found in sgn_people.sp_person and loaded into stock_owner
	my $person = CXGN::People::Person->get_person_by_username($dbh, 'SolCAP');
	#my $owner_q= "INSERT INTO sgn.stock_owner (stock_id, sp_person_id) VALUES (?,?)";
	#$owner_s = $dbh->prepate($owner_q);
	#$owner_s->execute($stock->stock_id(), $person->get_sp_person_id());
	
	my $donor_source = $spreadsheet->value_at($sct, "Donor Source:");
	$stock->create_stockprops( { 'donor source'  => $donor_source }, { autocreate => 1 } );
	
	my $institute = $spreadsheet->value_at($sct, "Donor Institution:");
	$stock->create_stockprops( { 'donor institution'  => $institute }, { autocreate => 1 } );

	my $country = $spreadsheet->value_at($sct, "Origin Country");
	$stock->create_stockprops( { country  => $country }, { autocreate => 1 } );

	my $state = $spreadsheet->value_at($sct, "Origin State/Province");
	$stock->create_stockprops( { state  => $state }, { autocreate => 1 } );

	my $adaptation = $spreadsheet->value_at($sct, "Adaptation (Humid/Arid)");
	$stock->create_stockprops( { adaptation  => $adaptation }, { autocreate => 1 } );

	my $male = $spreadsheet->value_at($sct, "Male");
	$stock->create_stockprops( { 'male parent'  => $male }, { autocreate => 1 } );

	my $female = $spreadsheet->value_at($sct, "Female");
	$stock->create_stockprops( { 'female parent' => $female }, { autocreate => 1 } );

	my $other = $spreadsheet->value_at($sct, "Other e.g. BC, IBC");
	$stock->create_stockprops( { pedigree  => $other }, { autocreate => 1 } );

	my $notes = $spreadsheet->value_at($sct, "Notes:");
	$stock->create_stockprops( { notes  => $notes }, { autocreate => 1 } );
	
	########
	my @props = $stock->search_related('stockprops');
	foreach  my $p ( @props )  {
	    print "**the prop value for stock " . $stock->name() . " is   " . $p->value() . "\n"  if $p;
	}
	#########
    }
};



if ($@) { print "An error occured! Rolling backl!\n\n $@ \n\n "; }
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    
    if ($last_cvtermprop_id) { $dbh->do("SELECT setval ('cvtermprop_cvtermprop_id_seq', $last_cvtermprop_id, true)"); }
    else { $dbh->do("SELECT setval ('cvtermprop_cvtermprop_id_seq', 1, false)"); }
    
    
}else {
    print "Transaction succeeded! Commiting cvtermprops! \n\n";
    $dbh->commit();
}
