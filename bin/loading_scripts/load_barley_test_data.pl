
=head1

load_cassava_data.pl

=head1 SYNOPSIS

    $this_script.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -u sgn user name
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION



=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

December 2011

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;
use CXGN::People::Person;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;
##
##

our ($opt_H, $opt_D, $opt_i, $opt_t, $opt_u);

getopts('H:i:tD:u:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				    }
    );
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } );
$dbh->do('SET search_path TO public');

#getting the last database ids for resetting at the end in case of rolling back
###############
my $last_nd_experiment_id = $schema->resultset('NaturalDiversity::NdExperiment')->get_column('nd_experiment_id')->max;
my $last_cvterm_id = $schema->resultset('Cv::Cvterm')->get_column('cvterm_id')->max;

my $last_nd_experiment_project_id = $schema->resultset('NaturalDiversity::NdExperimentProject')->get_column('nd_experiment_project_id')->max;
my $last_nd_experiment_stock_id = $schema->resultset('NaturalDiversity::NdExperimentStock')->get_column('nd_experiment_stock_id')->max;
my $last_nd_experiment_phenotype_id = $schema->resultset('NaturalDiversity::NdExperimentPhenotype')->get_column('nd_experiment_phenotype_id')->max;
my $last_phenotype_id = $schema->resultset('Phenotype::Phenotype')->get_column('phenotype_id')->max;
my $last_stock_id = $schema->resultset('Stock::Stock')->get_column('stock_id')->max;
my $last_stock_relationship_id = $schema->resultset('Stock::StockRelationship')->get_column('stock_relationship_id')->max;
my $last_project_id = $schema->resultset('Project::Project')->get_column('project_id')->max;
my $last_nd_geolocation_id = $schema->resultset('NaturalDiversity::NdGeolocation')->get_column('nd_geolocation_id')->max;
my $last_geoprop_id = $schema->resultset('NaturalDiversity::NdGeolocationprop')->get_column('nd_geolocationprop_id')->max;
my $last_projectprop_id = $schema->resultset('Project::Projectprop')->get_column('projectprop_id')->max;

my %seq  = (
    'nd_experiment_nd_experiment_id_seq' => $last_nd_experiment_id,
    'cvterm_cvterm_id_seq' => $last_cvterm_id,
    'nd_experiment_project_nd_experiment_project_id_seq' => $last_nd_experiment_project_id,
    'nd_experiment_stock_nd_experiment_stock_id_seq' => $last_nd_experiment_stock_id,
    'nd_experiment_phenotype_nd_experiment_phenotype_id_seq' => $last_nd_experiment_phenotype_id,
    'phenotype_phenotype_id_seq' => $last_phenotype_id,
    'stock_stock_id_seq'         => $last_stock_id,
    'stock_relationship_stock_relationship_id_seq'  => $last_stock_relationship_id,
    'project_project_id_seq'     => $last_project_id,
    'nd_geolocation_nd_geolocation_id_seq'          => $last_nd_geolocation_id,
    'nd_geolocationprop_nd_geolocationprop_id_seq'  => $last_geoprop_id,
    'projectprop_projectprop_id_seq'                => $last_projectprop_id,
    );

# find the cvterm for a phenotyping experiment
my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'phenotyping experiment',
      cv     => 'experiment type',
      db     => 'null',
      dbxref => 'phenotyping experiment',
    });

my $username = $opt_u || 'barley_test' ; #'cassavabase';
my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $username);

die "User $username for cassavabase must be pre-loaded in the database! \n" if !$sp_person_id ;


my $accession_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'accession',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'accession',
    });
my $plot_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'plot',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'plot',
    });
my $plot_of = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'plot_of',
      cv     => 'stock relationship',
      db     => 'null',
      dbxref => 'plot_of',
    });
my $population_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'population',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'population',
    });
my $member_of = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'member_of',
      cv     => 'stock relationship',
      db     => 'null',
      dbxref => 'member_of',
    });
########################

#new spreadsheet, don't skip first column
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);

# sp_term scale_name value name_string
my $scale_cv_name= "breeders scale";
# for this Unit Ontology has to be loaded!
my $unit_cv = $schema->resultset("Cv::Cv")->find(
    { name => 'unit.ontology' } );


my $organism = $schema->resultset("Organism::Organism")->find_or_create(
    {
	genus   => 'Hordeum',
	species => 'Hordeum vulgare'
    } );
my $organism_id = $organism->organism_id();
my $location = 'test';
#store a geolocation
my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create(
    {
        description => $location,
    } ) ;
 my $project = $schema->resultset("Project::Project")->find_or_create(
            {
                name => "Barley training set data",
                description => "test barley data for genomic selection",
            } ) ;
my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

my $population_name = 'Barley GS training population';
my $population = $schema->resultset("Stock::Stock")->find_or_create(
    { organism_id => $organism_id,
      name        => $population_name,
      uniquename  => $population_name,
      type_id     => $population_cvterm->cvterm_id,
    } );
eval {
    foreach my $name (@rows ) {
        my $stock_name = $name;
        print "Looking at stock $name \n";
        #store the plant accession in the plot table
        my $parent_stock = $schema->resultset("Stock::Stock")->find_or_create(
            { organism_id => $organism_id,
              name       => $stock_name,
              uniquename => $stock_name,
              type_id     => $accession_cvterm->cvterm_id,
            } );
        ##and create the stock_relationship with the population
        $population->find_or_create_related('stock_relationship_objects', {
	    type_id => $member_of->cvterm_id(),
	    subject_id => $parent_stock->stock_id(),
                                            } );
        #store the plot in stock
        my $plot_stock = $schema->resultset("Stock::Stock")->find_or_create(
	    { organism_id => $organism_id,
	      name  => $stock_name . " plot",
	      uniquename => $stock_name . " plot",
	      type_id => $plot_cvterm->cvterm_id()
	    });
        ##and create the stock_relationship with the accession
        $parent_stock->find_or_create_related('stock_relationship_objects', {
	    type_id => $plot_of->cvterm_id(),
	    subject_id => $plot_stock->stock_id(),
                                              } );
        #add the owner for this stock
	#check first if it exists
        my $owner_insert = "INSERT INTO phenome.stock_owner (sp_person_id, stock_id) VALUES (?,?)";
        my $sth = $dbh->prepare($owner_insert);
        my $check_query = "SELECT sp_person_id FROM phenome.stock_owner WHERE ( sp_person_id = ? AND stock_id = ? )";
        my $person_ids = $dbh->selectcol_arrayref($check_query, undef, ($sp_person_id, $parent_stock->stock_id) );
        if (!@$person_ids) {
            $sth->execute($sp_person_id, $parent_stock->stock_id);
        }
        $person_ids = $dbh->selectcol_arrayref($check_query, undef, ($sp_person_id, $plot_stock->stock_id) );
        if (!@$person_ids) {
            $sth->execute($sp_person_id, $plot_stock->stock_id);
        }
        #################
        ###store a new nd_experiment. One experiment per stock
        my $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->create(
            {
                nd_geolocation_id => $geolocation->nd_geolocation_id(),
                type_id => $pheno_cvterm->cvterm_id(),
            } );
        #link to the project
        $experiment->find_or_create_related('nd_experiment_projects', {
            project_id => $project->project_id()
                                            } );
        #link the experiment to the stock
        $experiment->find_or_create_related('nd_experiment_stocks' , {
            stock_id => $plot_stock->stock_id(),
            type_id  =>  $pheno_cvterm->cvterm_id(),
                                            });
        ##################
        LABEL: foreach my $label (@columns) {
            my $value =  $spreadsheet->value_at($name, $label);
            next() if $label eq  'Entry' ; #$value !~ /^\d/;
            print "Storing phenotypes for label $label! \n";
            ($value, undef) = split (/\s/, $value) ;
	    #print "Value $value \n";
	    #my ($db_name, $co_accession) = split (/\:/ , $label);
	    #print STDERR "db_name = '$db_name' sp_accession = '$sp_accession'\n";
	    #next() if (!$co_accession);
            my $cvterm = $schema->resultset('Cv::Cvterm')->create_with(
                { name => $label,
                  cv   => 'barley_test',
                  db   => 'barley',
                  dbxref => $label,
                });
            ####################
            ##make sure this rule is valid for all CO terms in the data file!!
            my $observable_term = $cvterm ;
            #############
            ##observable_id is the same as cvalue_id for scale and qscale, and the parent term for unit.
	    my $phenotype = $cvterm->find_or_create_related(
		"phenotype_cvalues", {
                    observable_id => $cvterm->cvterm_id,
		    value => $value ,
                    uniquename => "Stock: " . $plot_stock->stock_id . ", Term: " . $cvterm->name() ,
                });
	    print "Stored phenotype " . $phenotype->phenotype_id() . " (observable = " . $observable_term->name . ") with cvalue " . $cvterm->name . " value = $value \n\n" ;
            #link the phenotype to nd_experiment
            my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotypes', { phenotype_id => $phenotype->phenotype_id() } );
        }
    }
};


if ($@) { print "An error occured! Rolling backl!\n\n $@ \n\n "; }
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    foreach my $value ( keys %seq ) {
	my $maxval= $seq{$value} || 0;
	if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
}else {
    print "Transaction succeeded! Commiting ! \n\n";
    $dbh->commit();
}
