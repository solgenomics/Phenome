
=head1

load_cassava_data.pl

=head1 SYNOPSIS

    $this_script.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i  infile
 -u  sgn user name
 -m  use when loading a file with a 'location' field. This option forces -y , and loads project, year, and location
based on the location field and -y arg. instead of reading a metadata file.
 -y  year
 -a load parent information (only for files with female/male annotation)
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

Loading cassava phenotypes requires a phenotyping file using a standard template.
First column must contain unique identifiers, followed by the following column headers:

 PLOT REP  DESIG  BLOCK NOPLT NOSV

and columns for the phenotypes in ontology ID format (CO:0000123).
The loader also supports loading some  phenotype properties and units:

CO:0000099|scale:cassavabase
Terms loaded with a scale named "cassavabase" . Scale - to -value mapping must be pre-loaded into cvtermprop.

CO:0000018|unit:centimeter
Units will be added to phenotypeprop table. Units must be from the Unit Ontology L<http://www.obofoundry.org/cgi-bin/detail.cgi?id=unit>

CO:0000039|date:1MAP
timing of measurement in 'months after planting" (MAP) will be loaded as phenotype prop with a type_id of "months after planting"

=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

April 2013

=head2 TODO

Add support for boolean cvterm types
Add support for non-numeric values (scale and qscale types)

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;
use CXGN::People::Person;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;
use File::Basename;
use Try::Tiny;
##
##

our ($opt_H, $opt_D, $opt_i, $opt_t, $opt_u, $opt_m, $opt_y, $opt_a);

getopts('H:i:tD:u:may:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;
my $multilocation = $opt_m;

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

# for this Unit Ontology has to be loaded!
my $unit_cv = $schema->resultset("Cv::Cv")->find(
    { name => 'unit.ontology' } );

# find the cvterm for the unit "months after planting", used for assessing disease incidence and severity
my $map_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'months after planting',
      cv     => 'local',
      db     => 'local',
      dbxref => 'MAP',
    });
#Need to load cassava breeders scale for relevant traits. Currently the scale is defined
#in the cvterm definition.
my $scale_cv_name= "breeders scale";
########

# find the cvterm for a phenotyping experiment
my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'phenotyping experiment',
      cv     => 'experiment type',
      db     => 'null',
      dbxref => 'phenotyping experiment',
    });

my $username = $opt_u || 'kulakow' ; #'cassavabase';
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
########################

#new spreadsheet, skip first column
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 1);

# sp_term scale_name value name_string
my $scale_cv_name= "breeders scale";
# for this Unit Ontology has to be loaded!
my $unit_cv = $schema->resultset("Cv::Cv")->find(
    { name => 'unit.ontology' } );

my $organism = $schema->resultset("Organism::Organism")->find_or_create(
    {
	genus   => 'Manihot',
	species => 'Manihot esculenta',
    } );
my $organism_id = $organism->organism_id();

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

#location and project and year must be pre-loaded
my $geolocation;
my $geo_description;
my $project;
my $year;

if ($multilocation) {
    $year = $opt_y || die "must provide year (-y option) whren loading a multilocation file\n";
    #$location and $project will be loaded later based on the 'location' column in the data file
} else {
#new spreadsheet for the project and geolocation
    my $gp_file = $file . "metadata";
    my $gp = CXGN::Tools::File::Spreadsheet->new($gp_file);
    my @gp_row = $gp->row_labels();

    # get the project
    my $project_name = $gp->value_at($gp_row[0], "project_name");
    $project = $schema->resultset("Project::Project")->find(
        {
            name => $project_name,
        } );
    # get the geolocation
    $geo_description = $gp->value_at($gp_row[0], "geo_description");
    $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find(
        {
            description => $geo_description ,
        } );
    ##To build a unique plot name we need the project year and location
    #year is a projectprop , location is the geolocation description
    my $yearprop = $project->projectprops->find(
        { 'type.name' => 'project year' },
        { join => 'type'}
        ); #there should be only one project year prop.
    $year = $yearprop->value;
}
my $coderef = sub {
    ##unique#  PLOT REP  DESIG  BLOCK NOPLT NOSV CO:0000010	CO:0000099|scale:cassavabase  CO:0000018|unit:cm   CO:0000039|date:1MAP
    ##
    ##multilocation files:
    #unique#	location	PLOT	REP	DESIG	BLOCK	NOPLT	NOSV
    ##
    foreach my $num (@rows ) {
        my $replicate = $spreadsheet->value_at($num, "REP");
        if ($multilocation) {
            $geo_description = $spreadsheet->value_at($num, "location"); #
            $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create(
                {
                    description => $geo_description,
                    ##see if Peter has more data
                    #latitude => $latitude,
                    #longitude => $longitude,
                    #geodetic_datum => $datum,
                    #altitude => $altitude,
                } ) ;
            #store a project- combination of location and year
            $project = $schema->resultset("Project::Project")->find_or_create(
                {
                    name => "Cassava $geo_description $year",
                    description => "Plants assayed at $geo_description in $year",
                } ) ;
	    $project->create_projectprops( { 'project year' => $year }, { autocreate => 1 } );
        }
        ###
	my $plot = $spreadsheet->value_at($num, "PLOT");
        my $block =  $spreadsheet->value_at($num , "BLOCK");
        my $planted_plants =  $spreadsheet->value_at($num , "NOPLT");
        my $surv_plants= $spreadsheet->value_at($num , "NOSV"); ###############add this as a stock prop.
        my $clone_name = $spreadsheet->value_at($num , "DESIG");
        #look for an existing stock by name/synonym
        my ($parent_stock, $stock_name ) = find_or_create_stock($clone_name);
	##
	# if female/male parents are passed, add them to the database and link to the parent stock
	if ($opt_a) {
	    my $female_parent =  $schema->resultset("Cv::Cvterm")->create_with(
		{ name   => 'female_parent',
		  cv     => 'stock relationship',
		  db     => 'null',
		  dbxref => 'female_parent',
		});

	    my $male_parent =  $schema->resultset("Cv::Cvterm")->create_with(
		{ name   => 'male_parent',
		  cv     => 'stock relationship',
		  db     => 'null',
		  dbxref => 'male_parent',
		});

	    my $female_p =  $spreadsheet->value_at($num , "FEMALE");
	    my $male_p =  $spreadsheet->value_at($num , "MALE");
	    if ($female_p) {
		my ($female_stock, $female_stock_name)  = find_or_create_stock($female_p);
		# this should probably be changed around, so the female_parent is the object and the parent_stock is the subject! 
		# Check with Jeremy when he changes the pedigree interface. The same goes for the male_parent bellow
		$parent_stock->find_or_create_related('stock_relationship_objects', {
		    type_id => $female_parent->cvterm_id(),
		    subject_id => $female_stock->stock_id(),
						      } );
                print STDERR "FEMALE PARENT: " . $female_stock->name . "\n";
	    }
	    if ($male_p) {
                my ($male_stock, $male_stock_name)  = find_or_create_stock($male_p);
		###change this back to male_parent is the object.
                $parent_stock->find_or_create_related('stock_relationship_objects', {
                    type_id => $male_parent->cvterm_id(),
                    subject_id => $male_stock->stock_id(),
						    } );
                print STDERR "MALE PARENT: " . $male_stock->name . "\n";

            }
	    #################
	}
	##########
        #store the plot in stock. Build a uniquename first
        my $uniquename = $stock_name;
        if ($replicate) { $uniquename .=  "_replicate:" .  $replicate  ; }
        if ($block) { $uniquename .= "_block:" . $block ; }
	if ($plot) { $uniquename .= "_plot:" . $plot ; }
        $uniquename .= "_" . $year . "_" . $geo_description ;

        my $plot_stock = $schema->resultset("Stock::Stock")->find_or_create(
	    { organism_id => $organism_id,
	      name  => $uniquename,
	      uniquename => $uniquename,
	      type_id => $plot_cvterm->cvterm_id()
	    });
        #add stock properties to the plot
        if ($surv_plants) {
            $plot_stock->stockprops(
                {'surviving plants' => $surv_plants} , {autocreate => 1} );
        }
        if ($planted_plants) {
            $plot_stock->stockprops(
                {'planted plants' => $planted_plants} , {autocreate => 1} );
        }
        if ($replicate) { 
            $plot_stock->stockprops(
                {'replicate' => $replicate} , {autocreate => 1} );
        }
        if ($block) {
            $plot_stock->stockprops(
                {'block' => $block} , {autocreate => 1} );
        }
        ##and create the stock_relationship with the accession
        $parent_stock->find_or_create_related('stock_relationship_objects', {
	    type_id => $plot_of->cvterm_id(),
	    subject_id => $plot_stock->stock_id(),
                                              } );
        print STDERR "**Loading plot stock " . $plot_stock->uniquename . " (parent = " . $parent_stock->uniquename . ")\n\n";
        #add the owner for this stock
	#check first if it exists
        my $owner_insert = "INSERT INTO phenome.stock_owner (sp_person_id, stock_id) VALUES (?,?)";
        my $sth = $dbh->prepare($owner_insert);
        my $check_query = "SELECT sp_person_id FROM phenome.stock_owner WHERE ( sp_person_id = ? AND stock_id = ? )";
        my $person_ids = $dbh->selectcol_arrayref($check_query, undef, ($sp_person_id, $plot_stock->stock_id) );
        if (!@$person_ids) {
            $sth->execute($sp_person_id, $plot_stock->stock_id);
        }
        $person_ids = $dbh->selectcol_arrayref($check_query, undef, ( $sp_person_id, $parent_stock->stock_id) );
        if (!@$person_ids) {
            $sth->execute($sp_person_id, $parent_stock->stock_id);
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
	    my $value =  $spreadsheet->value_at($num, $label);
	    ($value, undef) = split (/\s/, $value) ;
	    #print "Value $value \n";

            #CO:0000039|MAP:1 #CO_334:0000033
            #db_name = CO , accession = 0000NNN
            #scale|unit|date(months after planting or MAP)
            #
            my ($full_accession, $full_unit ) = split(/\|/, $label);
            my ($value_type, $unit_value) = split(/\:/, $full_unit);
	    my ($db_name, $co_accession) = split (/\:/ , $full_accession);
	    #print STDERR "db_name = '$db_name' sp_accession = '$sp_accession'\n";
	    next() if (!$co_accession);
            my $co_term = $schema->resultset("General::Db")->find(
		{ name => 'CO' } )->find_related(
		"dbxrefs", { accession=>$co_accession , } )->find_related("cvterm" , {});
            ####################
            #skip non-numeric values
	    if ($value !~ /^\d/) {
                if ($value eq "\." ) { next; }
                warn "** Found non-numeric value in column $label (value = '" . $value ."'\n";
                next;
            }
	    ######################
	    # this is valid for scale and qscale value types
            #my $parent_cvterm = $schema->resultset("General::Db")->find(
            #	{ name => $db_name } )->find_related(
            #"dbxrefs", { accession=>$sp_accession , } )->find_related("cvterm" , {});
            # if the value type is 'unit' we use the actual parent term for
	    # the annotation. If it's a 'scale' we need to find out the appropriate
	    #child term, as stored in cvtermprop.
	    # cvtermprops need to be pre-loaded using load_scale_cvtermprops.pl
            ################################


            ##make sure this rule is valid for all CO terms in the data file!!
            my $observable_term = $co_term ;
            #############
            #the term should have PO and PATO mapping maybe TO?
            #make sure phenotype is loaded correctly for scale, unit, date
            #also store the unit in phenotype_cvterm
            #############################3
            ##observable_id is the same as cvalue_id for scale and qscale, and the parent term for unit.
	    my $phenotype = $co_term->find_or_create_related(
		"phenotype_cvalues", {
                    observable_id => $observable_term->cvterm_id, #co_term
		    #attr_id => $pato_id,
		    value => $value ,
                    uniquename => "Stock: " . $plot_stock->stock_id . ", Replicate: $replicate, Term: " . $co_term->name() ,
                });
	    print "Stored phenotype " . $phenotype->phenotype_id() . " (observable = " . $observable_term->name . ") with cvalue " . $co_term->name . " value = $value \n\n" ;
            #unit ontology term, will be assigned is value_type is "unit"
            #make sure unit ontology is loaded, and the unit_value in the file exists in UO
            my $unit_cvterm;
            if($value_type eq 'unit') { # unit:milimeter
                if ($unit_cv) {
                    #remove trailing spaces
                    $unit_value =~ s/^\s+//;
                    $unit_value =~ s/\s+$//;
                    ($unit_cvterm) = $unit_cv->find_related(
                        "cvterms" , { name => $unit_value } );
                    #make sure unit_cvterm is found
                    if (!$unit_cvterm) { warn "WARNING: Could not find term $unit_value in unit_ontology!\n"; }
                } else { warn "WARNING: Unit ontology is not loaded ! Cannot store unit $unit_value!\n";
                }
            }
            #date of measurement (such as moths after planting) is stored as a phenotype prop
            if ($value_type eq 'MAP') {
                $phenotype->create_phenotypeprops(
                    { 'months after planting' => $unit_value } , {autocreate => 1} ) ;
            }
            ##############Need to figure out how to handle different scales of the same trait.
            ###########See SolCAP potato data for a possible solution.
            ###########
            if ($value_type eq 'scale') {
                warn "SCALE is $unit_value, need to load this scale into cvtermprop!!\n\n";
            }
            ##############
            ##############
            # store the unit for the measurement (if exists) in phenotype_cvterm
            if ($unit_cvterm) {
                $phenotype->find_or_create_related("phenotype_cvterms" , {
                    cvterm_id => $unit_cvterm->cvterm_id() } );
                print "Loaded phenotype_cvterm with cvterm '" . $unit_cvterm->name() . "'\n" ;
            }
            #link the phenotype to nd_experiment
            my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotypes', { phenotype_id => $phenotype->phenotype_id() } );
        }
    }
    if ($opt_t) {
        die "TEST RUN! rolling back\n";
    }
};

try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting phenotyping experiments! \n\n"; }
} catch {
    # Transaction failed
    foreach my $value ( keys %seq ) {
        my $maxval= $seq{$value} || 0;
        if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
        else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};


sub find_or_create_stock {
    my $clone_name = shift;
    #clean clone name. Remove trailing spaces
    $clone_name =~ s/^\s+//;
    $clone_name =~ s/\s+$//;
    #remove /
    $clone_name =~ s/\///g;
    #
    my $stock_rs = $schema->resultset("Stock::Stock")->search(
        {
            -or => [
                 'lower(me.uniquename)' => { like => lc($clone_name) },
                 -and => [
                     'lower(type.name)'       => { like => '%synonym%' },
                     'lower(stockprops.value)' => { like => lc($clone_name) },
                 ],
                ],
        },
        { join => { 'stockprops' => 'type'} ,
          distinct => 1
        }
        );
    my $parent_stock;
    my $stock_name = $clone_name;
    if ($stock_rs->count >1 ) {
        print STDERR "ERROR: found multiple accessions for name $clone_name! \n";
        while ( my $st = $stock_rs->next) {
            print STDERR "stock name = " . $st->uniquename . "\n";
        }
        die ;
    } elsif ($stock_rs->count == 1) {
        $parent_stock = $stock_rs->first;
        $stock_name = $parent_stock->name;
    }else {
        #store the plant accession in the plot table
        $parent_stock = $schema->resultset("Stock::Stock")->create(
            { organism_id => $organism_id,
              name       => $stock_name,
              uniquename => $stock_name,
              type_id     => $accession_cvterm->cvterm_id,
            } );
    }
    return ($parent_stock, $stock_name);
}
