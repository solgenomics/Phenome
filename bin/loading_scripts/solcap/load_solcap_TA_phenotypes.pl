
=head1

load_solcap_TA_phenotypes.pl

=head1 SYNOPSIS

    $ThisScript.pl -H [dbhost] -D [dbname] [-t] -i infile 

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.
 -l location (e.g. 'Davis, California'). Confirm location as stored from the plot file into stockprop.
  -y year of the experiment (e.g. 2009)
  geolocation description and project name must match the names in a metadata.txt file


=head2 DESCRIPTION

This is a script for loading solcap phenotypes, as scored by using Tomato Analyzer software -post harvest 

See the solCap template for the 'TA_color', 'Longitudinal' and Latitudinal' spreadsheet for  more details 



=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

August 2010

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;
use CXGN::People::Person;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Date::Calc qw(
		  Delta_Days
		  check_date
		  );
use File::Basename;

use Carp qw /croak/ ;
use Try::Tiny;


our ($opt_H, $opt_D, $opt_i, $opt_t, $opt_l, $opt_y);

getopts('H:i:tD:l:y:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 1,
						 RaiseError => 1}
				    }
    );

my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] } );


#getting the last database ids for resetting at the end in case of rolling back
###############
my $last_nd_experiment_id = $schema->resultset('NaturalDiversity::NdExperiment')->get_column('nd_experiment_id')->max;
my $last_cvterm_id = $schema->resultset('Cv::Cvterm')->get_column('cvterm_id')->max;

my $last_nd_experiment_project_id = $schema->resultset('NaturalDiversity::NdExperimentProject')->get_column('nd_experiment_project_id')->max;
my $last_nd_experiment_stock_id = $schema->resultset('NaturalDiversity::NdExperimentStock')->get_column('nd_experiment_stock_id')->max;
my $last_nd_experiment_phenotype_id = $schema->resultset('NaturalDiversity::NdExperimentPhenotype')->get_column('nd_experiment_phenotype_id')->max;
my $last_phenotype_id = $schema->resultset('Phenotype::Phenotype')->get_column('phenotype_id')->max;

my %seq  = (
    'nd_experiment_nd_experiment_id_seq' => $last_nd_experiment_id,
    'cvterm_cvterm_id_seq' => $last_cvterm_id,
    'nd_experiment_project_nd_experiment_project_id_seq' => $last_nd_experiment_project_id,
    'nd_experiment_stock_nd_experiment_stock_id_seq' => $last_nd_experiment_stock_id,
    'nd_experiment_phenotype_nd_experiment_phenotype_id_seq' => $last_nd_experiment_phenotype_id,
    'phenotype_phenotype_id_seq' => $last_phenotype_id, 
    );


#new spreadsheet, skip first column
my $gp_file = dirname($file) . "/metadata.txt";
my $gp = CXGN::Tools::File::Spreadsheet->new($gp_file, 1);
my @gp_row = $gp->row_labels();

# get the project
my $project_name = $gp->value_at($gp_row[0], "project_name");

my $project = $schema->resultset("Project::Project")->find( {
    name => $project_name,
} );
# get the geolocation
my $geo_description = $gp->value_at($gp_row[0], "geo_description");
my ($geolocation) = $schema->resultset("NaturalDiversity::NdGeolocation")->search(
    { description => $geo_description , } );

my $location = $opt_l || die "Need the location for these plots. See load_solcap_plots.pl\n";
my $year = $opt_y || die "Need the year for the experiment. See load_solcap_plots.pl\n";
# find the cvterm for a phenotyping experiment
my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'phenotyping experiment',
      cv     => 'experiment type',
      db     => 'null',
      dbxref => 'phenotyping experiment',
    });


my $username = 'solcap_project';
my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $username);

die "User $username for Solcap must be pre-loaded in the database! \n" if !$sp_person_id ;

#find the cvterm for sgn person_id
my $person_id_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'sp_person_id',
      cv     => 'local',
      db     => 'null',
      dbxref => 'autocreated:sp_person_id',
    });

#new spreadsheet, skip  first columns
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 2);

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

my $coderef = sub {

    foreach my $row_label (@rows ) {
	#$plot number is the row label. Need to get the matching stock
	print "label # = $row_label\n";

        my $plot = $spreadsheet->value_at($row_label, "Plot #");
       	##########################################
	# find the child stock based on plot name
        my ($stock) = $schema->resultset("Stock::Stock")->search(
            { uniquename => { 'ilike' => $plot . '%' . $year . '%' . $location . '%'},
              name       => $plot
            } );
        if (!$stock) {
	    warn "no stock found for plot # $plot ! Skipping !!\n\n";
            next();
	}
	my $fruit_number =$spreadsheet->value_at($row_label, 'Fruit');
        ##
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
        #create experimentprop for the person_id
        if ($sp_person_id) {
            $experiment->find_or_create_related('nd_experimentprops', {
                value => $sp_person_id,
                type_id => $person_id_cvterm->cvterm_id,
                                                });
        }
        #link to the stock
        $experiment->find_or_create_related('nd_experiment_stocks' , {
            stock_id => $stock->stock_id(),
            type_id  =>  $pheno_cvterm->cvterm_id(),
                                            });
        ##
      COLUMN: foreach my $label (@columns) { 
	  my $value =  $spreadsheet->value_at($row_label, $label);

	  my ($db_name, $sp_accession) = split (/\:/ , $label);
	  next() if (!$sp_accession);
          if (!$value || $value =~ /^\.$/) { next; } ;

          my ($sp_term) = $schema->resultset("General::Db")->find( {
	      name => $db_name } )->find_related("dbxrefs", { 
		  accession=>$sp_accession , } )->search_related("cvterm");

	  my ($pato_term) = $schema->resultset("General::Db")->find( {
	      name => 'PATO' , } )->search_related
		  ("dbxrefs")->search_related
		  ("cvterm_dbxrefs", {
		      cvterm_id => $sp_term->cvterm_id() ,
                   });
	  my $pato_id = undef;
	  $pato_id = $pato_term->cvterm_id() if $pato_term;

	  #store the phenotype
	  my $phenotype = $sp_term->find_or_create_related("phenotype_observables", {
	      attr_id => $sp_term->cvterm_id(),
	      value => $value ,
	      cvalue_id => $pato_id,
	      uniquename => "$project_name, Fruit number: $fruit_number, plot: $plot, Term: " . $sp_term->name() ,
                                                           });

	  #check if the phenotype is already associated with an experiment
	  # which means this loading script has been run before .
	  if ( $phenotype->find_related("nd_experiment_phenotypes", {} ) ) {
	      warn "This experiment has been stored before! Skipping! \n phenotype attr=" . $sp_term->name  . "value = $value, PATO cvalue = $pato_id , uniquename = " . $phenotype->uniquename ."\n\n";
	      next();
	  }
	  print STDOUT "db_name = '$db_name' sp_accession = '$sp_accession'\n";
	  print "Value $value \n";
	  print "Stored phenotype " . $phenotype->phenotype_id() . " with attr " . $sp_term->name . " value = $value, cvalue = PATO " . $pato_id . "\n\n";
	  ########################################################

	  # link the phenotype with the experiment
	  my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotypes', { phenotype_id => $phenotype->phenotype_id() } );

	  # store the unit for the measurement (if exists) in phenotype_cvterm
	  #$phenotype->find_or_create_related("phenotype_cvterms" , {
	  #	cvterm_id => $unit_cvterm->cvterm_id() } ) if $unit_cvterm;
	  #print "Loaded phenotype_cvterm with cvterm '" . $unit_cvterm->name() . " '\n" if $unit_cvterm ;
      }
    }
    if ($opt_t) {
        die "TEST RUN! rolling back\n";
    }
};


try {
    $schema->txn_do($coderef);
    print "Transaction succeeded! Commiting phenotyping experiments! \n\n" if !$opt_t;
} catch {
    # Transaction failed
    foreach my $value ( keys %seq ) {
        my $maxval= $seq{$value} || 0;
        if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
        else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    die "An error occured! Rolling back  and reseting database sequences! " . $_ . "\n";
};
