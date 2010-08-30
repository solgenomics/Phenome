
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


#store a new project
my $project_name = 'solcap vintage tomatoes 2009, Fremont, OH';
my $p_description = 'solcap vintage tomatoes. OSU-OARDC North Central Agricultural Research Station, 1165 CR 43 Fremont, OH 43420';
my $project = $schema->resultset("Project::Project")->find_or_create( {
    name => $project_name,
    description => $p_description,
} ) ;

#store the geolocation data and props:

my $geo_description = 'OSU-OARDC Fremont, OH';

#Degrees and minutes followed by N(North) or S(South) 	41 20 56 N
my $latitude = 41+20/60+56/360;

#Degrees and minutes followed by E(East) or W(West)	83 7 2 W
my $longitude = -83-7/60-2/360;

my $datum= 'WGS84';

#Elevation (m asl)	191
my $altitude = 191;

my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create( {
    description => $geo_description,
    latitude => $latitude,
    longitude => $longitude,
    geodetic_datum => $datum,
    altitude => $altitude,
} ) ; 

my $year = '2009';
$geolocation->create_geolocationprops( { 'geolocation year' => $year }, { autocreate => 1 } );
my $address = 'OSU-OARDC North Central Agricultural Research Station, 1165 CR 43 Fremont, OH 43420';
$geolocation->create_geolocationprops( { 'geolocation address' => $address }, { autocreate => 1 } );


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
