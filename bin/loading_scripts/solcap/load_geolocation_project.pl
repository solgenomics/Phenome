
=head1

load_geolocation_project.pl

=head1 SYNOPSIS

    thisScript.pl  -H [dbhost] -D [dbname] -i inFile [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION



Naama Menda (nm249@cornell.edu)

    August 2010

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std; 
use CXGN::Tools::File::Spreadsheet;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;


use CXGN::People::Person;

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



#new spreadsheet, skip first column
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 1);

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

foreach my $name (@rows ) {
    my $project_description = $spreadsheet->value_at($name, "project_description");
    #store a new project
    my $project = $schema->resultset("Project::Project")->find_or_create( {
	name => $name,
        description => $project_description,
    } ) ;

    #store the geolocation data and props:
    my $geo_description = $spreadsheet->value_at($name, "geo_description");

    #Degrees and minutes followed by N(North) or S(South) 	41 20 56 N
    my $latitude = $spreadsheet->value_at($name, "latitude");

    #Degrees and minutes followed by E(East) or W(West)	83 7 2 W
    my $longitude =$spreadsheet->value_at($name, "longitude");

    my $datum= $spreadsheet->value_at($name, "datum");

    #Elevation (m asl)	191
    my $altitude = $spreadsheet->value_at($name, "altitude");

    my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create( {
	description => $geo_description,
	latitude => $latitude,
	longitude => $longitude,
	geodetic_datum => $datum,
	altitude => $altitude,
    } ) ;

    my $year = $spreadsheet->value_at($name, "year");

    $geolocation->create_projectprops( { 'project year' => $year }, { autocreate => 1 } );
    my $address = $spreadsheet->value_at($name, "address");

    $geolocation->create_geolocationprops( { 'geolocation address' => $address }, { autocreate => 1 } );

    my $sowing_date = $spreadsheet->value_at($name, "Sowing_date");
    $project->create_projectprops( { 'project sowing date' => $sowing_date }, { autocreate => 1 } ) if $sowing_date;

    my $trans_date = $spreadsheet->value_at($name, "Transplanting_date");
    $project->create_projectprops( { 'project transplanting date' => $trans_date }, { autocreate => 1 } ) if $trans_date;
    my $first_date = $spreadsheet->value_at($name, "First_Harvest_date");
    $project->create_projectprops( { 'project first harvest date' => $first_date }, { autocreate => 1 } ) if $first_date;
    my $last_date = $spreadsheet->value_at($name, "Last_Harvest_date");
    $project->create_projectprops( { 'project last harvest date' => $last_date }, { autocreate => 1 } ) if $last_date;

}


if ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    foreach my $value ( keys %seq ) {
	my $maxval= $seq{$value} || 0;
	#print  "$key: $value, $maxval \n";
	if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    $dbh->rollback;

}else {
    print "Transaction succeeded! Commiting project, geolocation, and geolocationprops! \n\n";
    $dbh->commit();
}
