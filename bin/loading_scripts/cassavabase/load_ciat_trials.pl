
=head1

load_ciat_trials.pl

=head1 SYNOPSIS

    thisScript.pl  -H [dbhost] -D [dbname] -i inFile [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 --types input file with trial types
 --sites input file with the geolication data of the trial sites
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

Load trial metadata for cassavabase experiments. This must be run prior to loading phenotyping esperiments.
Minimal metadata requirements are
    trial_name
    trial_description (can also be built from the trial name, type, year, location)
    trial_type (read from an input file)
    geo_description (site data to be read from --sites file) 
    year (can also be extracted from "sowing_date" )

Optional
    for geolocation:
     latitude
     longitude
     altitude
     datum

    other metadata
     sowing_date
     harvest_date
     sown_plants
     harvested_plants
     address (of field/experiment station)


Naama Menda (nm249@cornell.edu)

    April 2013

=cut


#!/usr/bin/perl
use strict;
use Getopt::Long;
use CXGN::Tools::File::Spreadsheet;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;
use Try::Tiny;
use DateTime;

use CXGN::Trial; # add project metadata 
use CXGN::BreedersToolbox::Projects; # associating a breeding program


my ( $dbhost, $dbname, $file, $sites, $types, $test);
GetOptions(
    'i=s'        => \$file,
    't'          => \$test,
    'sites|s=s'  => \$sites,
    'types|p=s'  => \$types,
    'dbname|D=s' => \$dbname,
    'dbhost|H=s' => \$dbhost,
);

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 1,
						 RaiseError => 1}
				  }
				    );
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] } );


#getting the last database ids for resetting at the end in case of rolling back
###############
my $last_geo_id = $schema->resultset('NaturalDiversity::NdGeolocation')->get_column('nd_geolocation_id')->max;
my $last_geoprop_id = $schema->resultset('NaturalDiversity::NdGeolocationprop')->get_column('nd_geolocationprop_id')->max;
my $last_project_id = $schema->resultset('Project::Project')->get_column('project_id')->max;


my %seq  = (
	    'nd_geolocation_nd_geolocation_id_seq' => $last_geo_id,
	    'nd_geolocationprop_nd_geolocationprop_id_seq' => $last_geoprop_id,
	    'project_project_id_seq' => $last_project_id,
	    );


my $ciat_project = $schema->resultset("Project::Project")->find_or_create( 
            {
                name => "CIAT",
	    } ) ;
        
#new spreadsheet, ## (skip first column ($file,1)  ) ###
#trial_name	type	site	sowing_date	harvest_date	sown_plants	harvested_plants
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);
my @trial_rows = $spreadsheet->row_labels();
my @trial_columns = $spreadsheet->column_labels();


#site	ZONA	name	longitude	latitude	altitude
my $sites_file = CXGN::Tools::File::Spreadsheet->new( $sites ) ;
my @site_rows = $sites_file->row_labels();
my @site_columns  = $sites_file->column_labels();

my %locations;

foreach my $site_id ( @site_rows ) {
    my $site_name = $sites_file->value_at($site_id , "name");
    my $department = $sites_file->value_at($site_id , "department");
    my $country = $sites_file->value_at($site_id , "country");
    my $long = $sites_file->value_at($site_id , "longitude");
    my $lat  = $sites_file->value_at($site_id , "latitude");
    my $alt  = $sites_file->value_at($site_id , "altitude");
    
    $locations{$site_id}->{site_name} = $site_name . ". " . $department . ", " . $country;
    $locations{$site_id}->{longitude} = $long;
    $locations{$site_id}->{latitude}  = $lat;
    $locations{$site_id}->{altitude}  = $alt;
}


#type	NOMBRE	name
my $types_file = CXGN::Tools::File::Spreadsheet->new( $types ) ;
my @type_rows = $types_file->row_labels();
my @type_columns  = $types_file->column_labels();

my %trial_types;
foreach my $type_id ( @type_rows ) {
    my $type_name = $types_file->value_at($type_id , "name");
    
    $trial_types{$type_id} = $type_name;
}

my $coderef= sub  {
    foreach my $name (@trial_rows ) {
        my $type_id = $spreadsheet->value_at($name, "type") ;
	my $project_type = $trial_types{$type_id} || $type_id ; # some project types are text-written in the file
	
	my $site_id = $spreadsheet->value_at($name, "site");
	my $location_name = $locations{$site_id}->{site_name} || $site_id ; #some sites are written in the file
	my $longitude = $locations{$site_id}->{longitude};
	my $latitude  = $locations{$site_id}->{latitudes};
	my $altitude  = $locations{$site_id}->{altitude};

	my $sowing_date  = $spreadsheet->value_at( $name, "sowing_date");
	my $harvest_date = $spreadsheet->value_at( $name, "harvest_date");
	my $sown_plants  = $spreadsheet->value_at( $name, "sown_plants");
	my $harvested_plants = $spreadsheet->value_at( $name, "harvested_plants");
        ###########
	my ($year, $formatted_sd) = reformat_date($sowing_date);
	my ($harvest_year, $formatted_hd) = reformat_date($harvest_date);
	##############
	
	my $project_description = "$name $project_type ($year) $location_name";
	
        ###store a new project
        print STDERR "Storing project name $name , description = $project_description\n";

        ##add warning if the project exists.
	#just create will make this fail if a project exists. 
	#This alleviates overloading projects with multiple properties that should not be there,
	#for example like year, and dates.
        my $project = $schema->resultset("Project::Project")->find_or_create( 
            {
                name => $name,
                description => $project_description,
            } ) ;
        
	#associate the new project with the CIAT breeding program (also stored in the project table
	my $cxgn_project =  CXGN::BreedersToolbox::Projects->new( { schema => $schema } ) ;

	$cxgn_project->associate_breeding_program_with_trial( $ciat_project->project_id, $project->project_id);
        print "ciat id = " . $ciat_project->project_id . " project_id = " . $project->project_id . "\n"; 	
        #store the geolocation data and props:
        my $geo_description = $location_name;

        #add warning if location exists
        my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create(
            {
                description => $geo_description,
                latitude => $latitude, ##needs to be reformatted in the CIAT file 
                longitude => $longitude,
                #geodetic_datum => $datum,
                altitude => $altitude,
            } ) ;
        print STDERR  "Stored geolocation '" . $geo_description . "'\n project year = $year\n";

	#store the geolocation_id as a projectprop for displaying on the trial page and the trial search.
	#not autocreating the cvterm 'project location' . Should be existing in each db.
	$project->create_projectprops( { 'project location' => $geolocation->nd_geolocation_id } );
	###
	##project type is a prop
	if ($project_type ) {
	    my $project_type_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
		{ name   => $project_type,
		  cv     => 'project_type' ,
		  db     => 'local',
		  dbxref => $project_type,
		});
	    
	    $project->create_projectprops( { $project_type => $project_type_cvterm->cvterm_id } , { cv_name => "project_type" } ); 
	}
        ####
        $project->create_projectprops( { 'project year' => $year }, { autocreate => 1 } );
        my $address; #does not exist in the CIAT data 
        if ($address) { $geolocation->create_geolocationprops( { 'geolocation address' => $address }, { autocreate => 1 } ); }

	if ($formatted_sd) { 
	    $project->create_projectprops( { 'project planting date' => $formatted_sd }, { autocreate => 1 } ); 
	}
        #
        if ($formatted_hd) {
	    $project->create_projectprops( { 'project harvest date' => $formatted_hd }, { autocreate => 1 } ) ;
	}
	if ($sown_plants) {
	    $project->create_projectprops( { 'project sown plants' => $sown_plants }, { autocreate => 1 } ) ;
	}
	if ($harvested_plants) {
	    $project->create_projectprops( { 'project harvested plants' => $harvested_plants }, { autocreate => 1 } ) ;
	}
	
	if ($test) {
	    die  "TEST RUN. Rolling back and reseting database sequences!!\n\n";
	}
    }
};

try {
    $schema->txn_do($coderef);
    if (!$test) { print "Transaction succeeded! Commiting project and its metadata \n\n"; }
} catch {
    # Transaction failed
    foreach my $value ( sort  keys %seq ) {
        my $maxval= $seq{$value} || 0;
        if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
        else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};


sub reformat_date {
    my $uf_date = shift;
    $uf_date =~ s/\s+?//g;
    #extract the year from the  date
    my ($month, $day, $year) = split "\/" , $uf_date;
    if ( $year < 15 && defined($year) && $year ) { $year = "20" . $year ; }
    elsif ( $year > 78 ) { $year = "19" . $year ; }
    else { 
	$year = "unknown" ;
    }
    if ( undef($uf_date) ) { $year = "unknown"; }
    my $timedate = 'unknown';
    my $formatted_date = 'unknown';
    if ( defined($month) && $day && $year ) {
	$timedate = DateTime->new(
	    year       => $year,
	    month      => $month,
	    day        => $day,
	    );
	$formatted_date = $year . "-" . $timedate->month_name . "-" . $day;
    }
    return ($year, $formatted_date);
}
