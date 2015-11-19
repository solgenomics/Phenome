
=head1

load_project_metadata.pl

=head1 SYNOPSIS

    thisScript.pl  -H [dbhost] -D [dbname] -i inFile [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

Load metadata for cassavabase experiments. This must be run prior to loading phenotyping esperiments.
Minimal metadata requirements are
    project_name
    project_description
    geo_description
    year

Optional
    for geolocation:
     latitude
     longitude
     altitude
     datum

    other metadata
    
     address (of field/experiment station)
     program (for linking to a breeding program in project_relationship) 

Naama Menda (nm249@cornell.edu)

    November 2015

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;
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
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] } );


#getting the last database ids for resetting at the end in case of rolling back
###############
my $last_geo_id = $schema->resultset('NaturalDiversity::NdGeolocation')->get_column('nd_geolocation_id')->max;
my $last_geoprop_id = $schema->resultset('NaturalDiversity::NdGeolocationprop')->get_column('nd_geolocationprop_id')->max;
my $last_project_id = $schema->resultset('Project::Project')->get_column('project_id')->max;
my $last_projectprop_id = $schema->resultset('Project::Projectprop')->get_column('projectprop_id')->max;
my $last_project_relationship_id = $schema->resultset('Project::ProjectRelationship')->get_column('project_relationship_id')->max;

my %seq  = (
	    'nd_geolocation_nd_geolocation_id_seq'             => $last_geo_id,
	    'nd_geolocationprop_nd_geolocationprop_id_seq'     => $last_geoprop_id,
	    'project_project_id_seq'                           => $last_project_id,
            'projectprop_projectprop_id_seq'                   => $last_projectprop_id,
            'project_relationship_project_relationship_id_seq' => $last_project_relationship_id, 
	    );



#new spreadsheet, skip first column
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

my $coderef= sub  {
    foreach my $name (@rows ) {
        my $project_description = $spreadsheet->value_at($name, "project_description") || $name;
        #store a new project
        print STDERR "Storing project name $name , description = $project_description\n";

        ##add warning if the project exists.
        my $project = $schema->resultset("Project::Project")->create( #just create will make this fail if a project exists. This alleviates overloading projects with multiple properties that should not be there , like year, and dates.
            {
                name => $name,
                description => $project_description,
            } ) ;
        #store the geolocation data and props:
        my $geo_description = $spreadsheet->value_at($name, "geo_description");
	
        #Degrees and minutes followed by N(North) or S(South) 	41 20 56 N
        my $latitude = $spreadsheet->value_at($name, "latitude") || undef;

        #Degrees and minutes followed by E(East) or W(West)	83 7 2 W
        my $longitude =$spreadsheet->value_at($name, "longitude") || undef;

        my $datum= $spreadsheet->value_at($name, "datum") || undef ;

        #Elevation (m asl)	191
        my $altitude = $spreadsheet->value_at($name, "altitude") || undef;
	
	#breeding program
	my $program = $spreadsheet->value_at($name, "program") || undef;

        #add warning if location exists
        print STDERR "Loading location $geo_description \n\n";
	my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create(
            {
                description => $geo_description,
                latitude => $latitude,
                longitude => $longitude,
                geodetic_datum => $datum,
                altitude => $altitude,
            } ) ;
        my $year = $spreadsheet->value_at($name, "year");
        print STDERR  "Stored geolocation '" . $geo_description . "'\n project year = $year\n";

        $project->create_projectprops( { 'project year' => $year }, { autocreate => 1 } );
        my $address = $spreadsheet->value_at($name, "address");

        if ($address) { $geolocation->create_geolocationprops( { 'geolocation address' => $address }, { autocreate => 1 } ); }

        #    project_name	project_description	geo_description	latitude	longitude	datum	altitude	planting_date	fertilizer_date	year	address
      

	####
	if ( $program )  { 
	    my $program_project = $schema->resultset("Project::Project")->find_or_create( 
            {
                name => $program,
		description => $program,
	    } ) ;
	    
	    # add projectprop 
	    $program_project->create_projectprops( { 'breeding_program' => '' } , { autocreate => 1 } );
	    
	    #add the project_relationship
	    my $breeding_program_trial_relationship = $schema->resultset("Cv::Cvterm")->create_with(
		{ name   => 'breeding_program_trial_relationship',
		  cv     => 'local' ,
		  db     => 'null',
		  dbxref => 'breeding_program_trial_relationship',
		});
	    $program_project->find_or_create_related('project_relationship_object_projects', 
						     {
							 type_id => $breeding_program_trial_relationship->cvterm_id(),
							 subject_project_id => $project->project_id(),
						     } );
	} ## breeding program stuff
    } #

    if ($opt_t) {
        die  "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    }
};

try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting project and its metadata \n\n"; }
} catch {
    # Transaction failed
    foreach my $value ( keys %seq ) {
        my $maxval= $seq{$value} || 0;
        if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
        else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};
