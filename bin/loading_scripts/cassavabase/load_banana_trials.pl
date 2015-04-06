
=head1

load_banana_trials.pl

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


my $iita_project = $schema->resultset("Project::Project")->find_or_create( 
            {
                name => "IITA",
	    } ) ;
        


my $coderef= sub  {
    #Preliminary yield trial data; location is Sendusu-IITA station; trial year 2010. 


    my $location_name = "Sendusu-IITA station";
    my $year = "2010";
    my $name = "Preliminary yield trial data, 2010";
    my $project_description = "Preliminary yield trial data, Sendusu-IITA station, 2010";
	
    my $project = $schema->resultset("Project::Project")->find_or_create( 
	{
	    name => $name,
	    description => $project_description,
	} ) ;
    
    #associate the new project with the IITA breeding program (also stored in the project table)
    my $cxgn_project =  CXGN::BreedersToolbox::Projects->new( { schema => $schema } ) ;
    
    $cxgn_project->associate_breeding_program_with_trial( $iita_project->project_id, $project->project_id);
    print "iita id = " . $iita_project->project_id . " project_id = " . $project->project_id . "\n"; 	
    #store the geolocation data and props:
    my $geo_description = $location_name;
    
    #add warning if location exists
    my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create(
	{
	    description => $geo_description,
	    #latitude => $latitude  , ##needs to be reformatted in the CIAT file 
	    #longitude => $longitude ,
	    #geodetic_datum => $datum,
	    #altitude => $altitude,
	} ) ;
    print STDERR  "Stored geolocation '" . $geo_description . "' project year = $year\n";
    $project->create_projectprops( { 'project year' => $year }, { autocreate => 1 } );
    
    #store the geolocation_id as a projectprop for displaying on the trial page and the trial search.
    #not autocreating the cvterm 'project location' . Should be existing in each db.
    $project->create_projectprops( { 'project location' => $geolocation->nd_geolocation_id } );
    ####
    ##project type is a prop
    #if ($project_type ) {
    #    my $project_type_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
    #	{ name   => $project_type,
    #	  cv     => 'project_type' ,
    #	  db     => 'local',
    #	  dbxref => $project_type,
    #	});
    
    #    $project->create_projectprops( { $project_type => $project_type_cvterm->cvterm_id } , { cv_name => "project_type" } ); 
    #}
    ####
    
    if ($test) {
	die  "TEST RUN. Rolling back and reseting database sequences!!\n\n";
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


