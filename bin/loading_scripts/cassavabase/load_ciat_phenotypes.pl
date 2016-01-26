
=head1

load_ciat_phenotypes.pl

=head1 SYNOPSIS

    $this_script.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i  infile
 -u  sgn user name
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

Loading cassava phenotypes requires a phenotyping file using a standard template.
First column must contain unique identifiers, followed by the following column headers:

#  variery   trial   replicate  CO_334:0000010

and columns for the phenotypes in ontology ID format (CO:0000123).


=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

February 2015

=head2 TODO


=cut


#!/usr/bin/perl
use strict;
use Getopt::Long;
use CXGN::Tools::File::Spreadsheet;
use CXGN::People::Person;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;
use File::Basename;
use Try::Tiny;
##
##


my ( $dbhost, $dbname, $file, $sites, $types, $test, $username );
GetOptions(
    'i=s'        => \$file,
    'u=s'        => \$username,
    't'          => \$test,
    'dbname|D=s' => \$dbname,
    'dbhost|H=s' => \$dbhost,
);


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

# find the cvterm for a phenotyping experiment
my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'phenotyping experiment',
      cv     => 'experiment_type',
      db     => 'null',
      dbxref => 'phenotyping experiment',
    });

my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $username);

die "User $username for cassavabase must be pre-loaded in the database! \n" if !$sp_person_id ;


my $accession_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'accession',
      cv     => 'stock_type',
      db     => 'null',
      dbxref => 'accession',
    });
my $plot_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'plot',
      cv     => 'stock_type',
      db     => 'null',
      dbxref => 'plot',
    });
my $plot_of = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'plot_of',
      cv     => 'stock_relationship',
      db     => 'null',
      dbxref => 'plot_of',
    });
########################

#new spreadsheet, skip first column
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 1);

my $organism = $schema->resultset("Organism::Organism")->find_or_create(
    {
	genus   => 'Manihot',
	species => 'Manihot esculenta',
    } );
my $organism_id = $organism->organism_id();

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

#location and project and year must be pre-loaded
# get location and year from the pre-loaded trials ("project") see
#load_ciat_trials.pl

my $coderef = sub {
    ##variery  trial   relicate   CO_334:0000010
    foreach my $num (@rows ) {
        my $accession = $spreadsheet->value_at($num, "variety");
	##CIAT accessions might have whitespaces 
	$accession =~ s/\s+?//g;
	######
	my $project_name = $spreadsheet->value_at($num, "trial");
	###find the project object and its year
	my $project = $schema->resultset("Project::Project")->find(
	    { name => $project_name,
	    } );
	if (!$project) {
	    warn "***NO PROJECT LOADED FOR $project_name (row $num accession $accession). Check your loaded trials\n\n";
	    next;
	}
	print "Project = $project_name\n";
	my $project_year_cvterm = $schema->resultset("Cv::Cvterm")->find(
	    { name => 'project year', } );
	my $projectprops = $project->find_related("projectprops", { type_id=> $project_year_cvterm->cvterm_id , } );
	my $year = $projectprops->value; 
	my $replicate = $spreadsheet->value_at($num, "replicate");
	
	##find the geolocation of the project
	my $project_location_cvterm = $schema->resultset("Cv::Cvterm")->find(
	    { name => "project location" , } );
	my $projectprops = $project->find_related("projectprops", { type_id=>  $project_location_cvterm->cvterm_id , } );
	my $geolocation_id = $projectprops->value; 
	###create a unique plot name
	###
	#look for an existing stock by name/synonym
        my $parent_stock = find_or_create_stock($accession);
	my $stock_name = $parent_stock->name;
	##
	##########
        #store the plot in stock. Build a uniquename first
       	my $plot_name = $stock_name;
        if ($replicate) { 
	    $plot_name .=  "_" . $replicate ;
	}
	$plot_name .= "_" . $year . "_" . $project_name ;

        my $plot_stock = $schema->resultset("Stock::Stock")->find_or_create(
	    { organism_id => $organism_id,
	      name  => $plot_name,
	      uniquename => $plot_name,
	      type_id => $plot_cvterm->cvterm_id()
	    });
        #add stock properties to the plot
        if ($replicate) { 
            $plot_stock->stockprops(
                {'replicate' => $replicate} , {autocreate => 1} );
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
                nd_geolocation_id => $geolocation_id,
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

            # #CO_334:0000033
            #db_name = CO , accession = 0000NNN
	    #
	    my ($db_name, $co_accession) = split (/\:/ , $label);
	    #print STDERR "db_name = '$db_name' co_accession = '$co_accession'\n";
	    next() if (!$co_accession);
	    
            my $co_term = $schema->resultset("General::Db")->find(
		{ name => 'CO' } )->find_related(
		"dbxrefs", { accession=>$co_accession , } )->find_related("cvterm" , {});
            ####################
	    
            #skip non-numeric values
	    if ($value !~ /^\d/) {
                if ($value eq "\." || !$value ) { next; }
                warn "** Found non-numeric value in column $label (value = '" . $value ."'\n";
                next;
            }

            ##make sure this rule is valid for all CO terms in the data file!!
            my $observable_term = $co_term ;
            #############
            #the term should have PO and PATO mapping maybe TO?
            #make sure phenotype is loaded correctly for scale, unit, date
            #also store the unit in phenotype_cvterm
            #############################
            ##observable_id is the same as cvalue_id for scale and qscale, and the parent term for unit.
	    my $phenotype = $co_term->find_or_create_related(
		"phenotype_cvalues", {
                    observable_id => $observable_term->cvterm_id, #co_term
		    #attr_id => $pato_id,
		    value => $value ,
                    uniquename => "Stock: " . $plot_stock->stock_id . ", Replicate: $replicate, Term: " . $co_term->name() ,
                });
	    print "Stored phenotype " . $phenotype->phenotype_id() . " (observable = " . $observable_term->name . ") with cvalue " . $co_term->name . " value = $value \n\n" ;
            ##############
            #link the phenotype to nd_experiment
            my $nd_experiment_phenotype = $experiment->find_or_create_related('nd_experiment_phenotypes', { phenotype_id => $phenotype->phenotype_id() } );
        }
    }
    if ($test) {
        die "TEST RUN! rolling back\n";
    }
};

try {
    $schema->txn_do($coderef);
    if (!$test) { print "Transaction succeeded! Commiting phenotyping experiments! \n\n"; }
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
    return $parent_stock;
}
