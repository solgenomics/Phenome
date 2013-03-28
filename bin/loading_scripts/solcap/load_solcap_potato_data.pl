
=head1

load_solcap_potato_data.pl

=head1 SYNOPSIS

    $this_script.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.
 -p  project name as loaded in the project table
 -g  geolocation description as loaded in the nd_geolocation table
 -n population name
 -y year. "Year" column in spreadsheet overrides
 -m metadata file - for project name and geolocation

=head2 DESCRIPTION

this loading script is based on load_solcap_data_entry, but since the potato data from 2009 has different spreadsheet format, it requires different handling. The data is stored in the Chado Stock, Natural Diversity, and Phenotype modules.
Let's hope the future SolCAP potato data would be stored in the same format!!

=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

June 2011

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;
use Try::Tiny;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;
##

use CXGN::Chado::Dbxref;
use CXGN::Chado::Phenotype;
##

my %value_map = (
    'SP:0000009' => { # flower color
        L => 'light',
        M => 'medium',
        R => 'red',
        P => 'purple',
        W => 'white',
        B => 'blue',
        '^' => 'white flower tips',
        '*' => 'white star pattern',
        '#' => 'white dots',
        '@' => 'white speckles',
        '~' => 'ruffled margins',
    },
    );

### This stuff is the same as the tomato solcap phenotype loaded

our ($opt_H, $opt_D, $opt_i, $opt_t, $opt_p, $opt_g, $opt_n, $opt_y, $opt_m);

getopts('H:i:tD:p:g:y:m:n:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;
my $metadata = $opt_m;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 1,
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

my %seq  = (
    'nd_experiment_nd_experiment_id_seq' => $last_nd_experiment_id,
    'cvterm_cvterm_id_seq' => $last_cvterm_id,
    'nd_experiment_project_nd_experiment_project_id_seq' => $last_nd_experiment_project_id,
    'nd_experiment_stock_nd_experiment_stock_id_seq' => $last_nd_experiment_stock_id,
    'nd_experiment_phenotype_nd_experiment_phenotype_id_seq' => $last_nd_experiment_phenotype_id,
    'phenotype_phenotype_id_seq' => $last_phenotype_id,
    'stock_stock_id_seq'         => $last_stock_id,
    'stock_relationship_stock_relationship_id_seq'  => $last_stock_relationship_id,
    );


# get the project
my $project_name = $opt_p || warn "Need project name! (option -p). See load_geolocation_project.pl if you have not loaded the project\n";
my $project_description = $project_name;

# get the geolocation
my $geo_description = $opt_g || warn "Need a geo_description (option -g). See load_geolocation_project.pl if you have not loaded the project's geolocation";

if ($metadata) {
    my $m = CXGN::Tools::File::Spreadsheet->new($metadata,1);
    my @rows = $m->row_labels;
    $project_name = $rows[0];
    $project_description = $m->value_at($project_name, "project_description");
    $geo_description = $m->value_at($project_name,"project_description");
}
if (!$project_name) { die "NEED a project_name from option -p or from a metadata file (option -m)\n"; }
my $project = $schema->resultset("Project::Project")->find_or_create( {
    name => $project_name,
    description =>$project_description
} );

my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find(
    { description => $geo_description , } );

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

#the cvterm for the population
print "Finding/creating cvterm for population\n";
my $population_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'population',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'population',
    });


my $organism = $schema->resultset("Organism::Organism")->find_or_create( {
    species => 'Solanum tuberosum' } );
my $organism_id = $organism->organism_id();
my $population_name = $opt_n || die "Need a potato population name to proceed! (-n option) \n";

my $population = $schema->resultset("Stock::Stock")->find_or_create(
    {
        name        => $population_name,
        uniquename  => $population_name,
        organism_id => $organism_id,
        type_id     => $population_cvterm->cvterm_id
    } );
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
#the cvterm for the relationship type
print "Finding/creating cvterm for stock relationship 'member_of' \n";
my $member_of = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'member_of',
      cv     => 'stock relationship',
      db     => 'null',
      dbxref => 'member_of',
    });
########################

#new spreadsheet, skip first column
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 1);

# sp_term scale_name value name_string
my $scale_cv_name= "breeders scale";
# for this Unit Ontology has to be loaded!
my $unit_cv = $schema->resultset("Cv::Cv")->find(
    { name => 'unit.ontology' } );


my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();
my $year = $opt_y; #get this as an option . "year" column in spreadsheet overrides

my $coderef = sub  {
    my $date; # the date column changes more than once in the spreadsheet, meaning following column values were collected at that date.
    foreach my $label (@rows ) {
        #2009 data requires first loading of metadata with load_geolocation_project.pl
        #2010-11 data has following metadata columns
        #line	market	ploidy	release year	release reange	entry	year	location	replicate

        my $date_count = 0;
        my $parent_accession = $spreadsheet->value_at($label, "line");
        #find the stock for the parent accession
	my $parent_stock = $schema->resultset("Stock::Stock")->find_or_create(
	    { organism_id => $organism_id,
	      name  => $parent_accession,
	      uniquename => $parent_accession,
	      type_id => $accession_cvterm->cvterm_id,
            });
        #add the parent accession to the potato population
        $population->find_or_create_related('stock_relationship_objects', {
	    type_id => $member_of->cvterm_id,
	    subject_id => $parent_stock->stock_id,
                                            } );
        my $plot;
        if (grep(/plot/,  @columns ) ) {
            $plot = $spreadsheet->value_at($label, "plot");
        }
        my $replicate = $spreadsheet->value_at($label, "replicate");
        my $year = $spreadsheet->value_at($label, "year");
        if (!$opt_g) {
            # don't have these values from solcap 2010-11, so keeping these undef
            my ($latitude, $longitude, $datum, $altitude);
            my $location = $spreadsheet->value_at($label, "location");
            my $plot = $location;
            my $geo_description = $project_name . " " . $location . " " . $year ;
            $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create(
                {
                    description => $geo_description,
                    latitude => $latitude,
                    longitude => $longitude,
                    geodetic_datum => $datum,
                    altitude => $altitude,
                } ) ;
        }

	my $uniquename = $parent_accession ."_plot_".$plot."_".$replicate."_".$year."_".$geo_description;
        #store the plot in stock
        my $plot_stock = $schema->resultset("Stock::Stock")->find_or_create(
	    { organism_id => $organism_id,
	      name  => $plot,
	      uniquename => $uniquename,
	      type_id => $plot_cvterm->cvterm_id()
	    });
        ##and create the stock_relationship with the accession
        $parent_stock->find_or_create_related('stock_relationship_objects', {
	    type_id => $plot_of->cvterm_id(),
	    subject_id => $plot_stock->stock_id(),
                                              } );
        #add the owner for this stock
	my $owner_insert = "INSERT INTO phenome.stock_owner (sp_person_id, stock_id) VALUES (?,?)";
        my $sth = $dbh->prepare($owner_insert);
        $sth->execute($sp_person_id, $plot_stock->stock_id);
        $sth->execute($sp_person_id, $parent_stock->stock_id);
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

        LABEL: foreach my $col_label (@columns) {
	    my $value =  $spreadsheet->value_at($label, $col_label);
	    ($value, undef) = split (/\s/, $value) ;
	    print "label = $col_label , Value $value \n";
	    next() if $value !~ /^\d/;
            if (grep(/date/,  @columns ) ) {
                $date = $spreadsheet->value_at($label, 'date') unless $date_count;
            }
	    if ($col_label =~ /date\d/) {
		$date_count++;
		##print "***Changing date $date \n\n ";
		#make sure extra 'date' colums have sequencial numeric suffix starting at 1
                $date = $spreadsheet->value_at($label, "date" . $date_count);
                ########################
                # when the date changes, need to store a new nd_experiment_id
                $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->create(
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

                #########################
	    }
            ##The date is the nd_experimentprop
            if ($date) {
                $experiment->create_nd_experimentprops(
                    { date => $date } ,
                    { autocreate => 1 , cv_name => 'local' }
                    );
            }
            ## label = SP:0000212|scale:NE1014 , Value 7
            ## db_name = 1026, sp= , type =
            #sp terms have a lable to determine if these have a scale or a quantitative unit
            my ($term, $type) = split (/\|/ , $col_label) ;
            #db_name = SP , accession = 0000NNN
	    my ($db_name, $sp_accession) = split (/:/ , $term);
            print "db_name = $db_name, sp= $sp_accession, type = $type\n";
	    #print STDERR "db_name = '$db_name' sp_accession = '$sp_accession'\n";
	    next() if (!$sp_accession);
            ####################
	    ######################

            #value type should be 'scale', 'qscale' or 'unit'
	    #unit_name should be the scale/qscale name or unit name
            #these terms will be stored in the phenotype table as follows:

            ####unit (e.g. 'tuber length' in  'milimeters')
            #observable_id = tuber length cvterm_id (same as cvalue_id)##########not 'tuber PO id'
            #atrr_id       = 'length' PATO id
            #cvalue_id     = 'tuber length cvterm_id'
            # value        = the recorder value of the trait
            #### phenotype_cvterm: cvterm_id = 'milimeter id'
	    ###
            ###qscale (qualitative e.g. tuber flesh color yellow)
            #observable_id = tuber flesh color cvterm_id (parent_id of cvalue_id) ############not 'tuber flesh PO id'
            #atrr_id       = 'color' PATO id
            #cvalue_id     = 'tuber flesh color yellow cvterm_id'
            # value        = 'yellow' (get this value from cvtermprop where cvterm_id = the cvalue_id)

            ###
            ###scale (continuous scale e.g. tuber eye depth = 3)
            #observable_id = tuber eye depth cvterm_id (parent of cvalue_id) ##### not 'tuber eye PO id'
            #atrr_id       = 'depth' PATO id
            #cvalue_id     = 'tuber eye depth 3  cvterm_id'
            # value        = the recorder numeric value of the trait (since qtl analysis of a continuous scale has a meaning)
            ### PO and PATO terms should come from the cvterm_dbxref mapping of the 'parent term' (i.e. 'tuber eye depth' should be  mapped to PO 'tuber eye' and PATO 'depth'

            my ($value_type, $unit_name) = split (/\:/, $type) ;

	    # this is valid for scale and qscale value types
            my $parent_cvterm = $schema->resultset("General::Db")->find(
		{ name => $db_name } )->find_related(
		"dbxrefs", { accession=>$sp_accession , } )->find_related("cvterm" , {});
            # if the value type is 'unit' we use the actual parent term for
	    # the annotation. If it's a 'scale' we need to find out the appropriate
	    #child term, as stored in cvtermprop.
	    # cvtermprops need to be pre-loaded using load_scale_cvtermprops.pl
	    my $sp_term = $parent_cvterm;
            my $observable_term = $parent_cvterm;
	    my $unit_cvterm; # cvterm for the unit specified in the file

	    if ($value_type eq 'scale' || $value_type eq 'qscale') { ##(e.g. scale:PVP) ##
		my ($cvterm_type) = $schema->resultset("Cv::Cv")->find(
		    { name => 'breeders scale' } )->find_related(
		    'cvterms' , { name  => $unit_name} );
		my $type_id = $cvterm_type->cvterm_id() if $cvterm_type || croak 'NO CVTERM FOUND FOR breeders_scale $unit_name! Cvterms for scales must be pre-loaded.  Cannot proceed';
                # find the mapped value for relevant sp terms
		# some values are used outside the definitions of trait scales
		# For such cases I've mapped numeric values to the most relevant
		# existing value from the pre-defined scale.
		# this usually happens for logically contineuos scales (e.g. 1=very poor, 9 =excellent) thus the actual value used for scoring the phenotype is stored in the phenotype table for allowing more acurate quantitative analysis,
		# although these scores may be very subjective.

                #value for flower color
                ################so far no flower color is recorded in the potato data
                #########$value_map will have to be tweaked when such data is recieved
		$value = $value_map{$term}{$value} if $value_map{$term};
		################

		my ($cvtermprop)= $parent_cvterm->search_related("cvtermpath_objects")->search_related('subject')->search_related(
		    "cvtermprops", { 'cvtermprops.type_id' => $type_id,
				     'cvtermprops.rank' => $value ,
		    } );
                print "parent term is " . $parent_cvterm->name() . "\n";
		print "Found cvtermprop " . $cvtermprop->get_column('value') . " for child cvterm '" . $cvtermprop->find_related("cvterm", {})->name() . "'\n\n" if $cvtermprop ;
		if (!$cvtermprop) {
                    warn("NO cvtermprop found for term '$term' , value '$value'! Cannot proceed! Check your input!!") ;
                    next LABEL;
                }
		$sp_term = $cvtermprop->cvterm() ;
                ####if the value type is qscale,
                ####need to store the cvtermprop value in phenotype.value
                print "**term  = " . $parent_cvterm->name . " rank = $value \n\n";
                #if ($value_type eq 'qscale') {
                $value = $cvtermprop->value;
                print "**Value for parent term "  . $parent_cvterm->name. " ($term) is $value! \n"
                #}
                ######## if the value type is 'unit' need to store it in phenotype_cvterm
            } elsif ($value_type eq 'unit') { # unit:milimeter
                ($unit_cvterm) = $unit_cv->find_related(
                    "cvterms" , { name => $unit_name } ) if $unit_cv ;
                $observable_term = $sp_term;
            }
            #############
            #the term should have PO and PATO mapping
            my ($pato_cvterm) = $schema->resultset("General::Db")->find(
		{ name => 'PATO' , } )->search_related
		("dbxrefs")->search_related
		("cvterm_dbxrefs", {
		    cvterm_id => $sp_term->cvterm_id() ,
		 });
	    my $pato_id = undef;
	    $pato_id = $pato_cvterm->cvterm_id() if $pato_cvterm;

            my ($po_cvterm) = $schema->resultset("Cv::Cv")->find(
		{ name => 'plant_structure' , } )->search_related
		("cvterms", { cvterm_id => $sp_term->cvterm_id ,} );
            my $po_id = undef;
	    $po_id = $po_cvterm->cvterm_id() if $po_cvterm;

            #make sure phenotype is loaded correctly for scale, qscale, unit. 
            #also store the unit in phenotype_cvterm
            #############################3
            ##observable_id is the same as cvalue_id for scale and qscale, and the parent term for unit.

	    my $phenotype = $sp_term->find_or_create_related(
		"phenotype_cvalues", {
                    observable_id => $observable_term->cvterm_id, #sp_term
		    attr_id => $pato_id,
		    value => $value ,
                    uniquename => "Stock: " . $plot_stock->stock_id . ", Replicate: $replicate, plot: $plot," . ", Term: " . $sp_term->name() . ", parent:  $term",
                });
	    print "Stored phenotype " . $phenotype->phenotype_id() . " (observable = " . $parent_cvterm->name . ") with cvalue " . $sp_term->name . " value = $value, attr = PATO " . $pato_id . "\n\n";
            # store the unit for the measurement (if exists) in phenotype_cvterm
	    $phenotype->find_or_create_related("phenotype_cvterms" , {
		cvterm_id => $unit_cvterm->cvterm_id() } ) if $unit_cvterm;
	    print "Loaded phenotype_cvterm with cvterm '" . $unit_cvterm->name() . " '\n" if $unit_cvterm ;

            #link the phenotype to nd_experiment
            my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotypes', { phenotype_id => $phenotype->phenotype_id() } );
        }
    }
};

#accession= Premier Russet, cloumn = SP:0000201|scale:NE1014, value = 4
try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting stocks and phenotypes \n\n"; }
} catch {
    # Transaction failed
    foreach my $value ( keys %seq ) {
        my $maxval= $seq{$value} || 0;
        if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
        else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};

#    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
