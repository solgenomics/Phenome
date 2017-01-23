#!/usr/bin/perl

=head1 NAME

add_trial_design-layout.pl
 - add design and layout to trials without design.
 - It uses the TrialDesignStore function.
 - implemented for earlier trials uploaded from backend.
 - get the plot and block number from the stock names (plot names).
 - if plot and block number is not found in the plot name, it generate sequence of numbers as plot number, use 1 as the block number and set design to 'CRD'.


=head1 DESCRIPTION

add_trial_design.pl -H [database host] -D [database name] trial_file.txt

Options:

 -H the database host
 -D the database name

 trial_file.txt : A file with two columns: trial name, trial design.
 		- also works if the trial design column is empty.

=head1 AUTHOR

Alex Ogbonna <aco46@cornell.edu>

=cut


use strict;
use warnings;
use Bio::Chado::Schema;
use Getopt::Std;
use CXGN::DB::InsertDBH;
use SGN::Model::Cvterm;
use CXGN::Trial::TrialDesignStore;
use CXGN::BreedersToolbox::Projects;
use Data::Dumper;
use CXGN::Trial;
use Try::Tiny;


our ($opt_H, $opt_D);
getopts("H:D:");
my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = shift;
my $c = shift;
my @trial_names;
my @trial_designs;
my $accession;
my $program_id;
my $plot_number;
my $block_number;
my $trial_location_id;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>"$dbhost",
				   dbname=>"$dbname",
				   dbargs => {AutoCommit => 1,
					      RaiseError => 1,
				   }

				 } );

my $schema = Bio::Chado::Schema->connect( sub { $dbh->get_actual_dbh() });
my $program_object = CXGN::BreedersToolbox::Projects->new( { schema => $schema });

#get design cvterm_id
my $design_cvterm_id = $schema->resultset("Cv::Cvterm")->search( {name => 'design' }, )->first->cvterm_id;
my $accession_cvterm_id = $schema->resultset("Cv::Cvterm")->search( {name => 'accession' }, )->first->cvterm_id;
my $plot_cvterm = SGN::Model::Cvterm->get_cvterm_row($schema, 'plot', 'stock_type') ;
my $plot_cvterm_id = $plot_cvterm->cvterm_id;

#opening input file and retrieving trial_names and trial_designs
open (my $file_fh, "<", $file ) || die ("\nERROR: the file $file could not be found\n" );

my $header = <$file_fh>;
while (my $line = <$file_fh>) {
    chomp $line;
    my ($trial_name,$trial_design) = split("\t", $line);

    my %design_entry;
    my @plot_numbers_array;
    my @block_numbers_array;
    my @plot_names_array;
    my @plot_id_array;
    my @accession_array;
    my $project_id;
    
    if (!$trial_design){
	$trial_design = 'RCBD';
    }
    print "Adding design and layout for trial: $trial_name\n";
    
    #getting trial id from trial name provided
    $project_id = $schema->resultset("Project::Project")->search({name => $trial_name})->first->project_id;
    print "PROJECT_ID: $project_id\n";
    
    #search if trial has design
    my $find_design = $schema->resultset('Project::Projectprop')->find(
	{
	    project_id => $project_id,
	    type_id => $design_cvterm_id
	});
    
    #Insert design if trial has no design
    if (!$find_design){
	my $set_design = $schema->resultset('Project::Projectprop')->create(
	    {
		project_id => $project_id,
		type_id => $design_cvterm_id,
		value => $trial_design
	    });
    }else {
	print "Design " .  $find_design->value . " found for this trial...\n";
    }
    
    # get trial location name and id
    my $trials = CXGN::Trial->new({bcs_schema=>$schema, trial_id=>$project_id});
    my $location = $trials->get_location();
    #print STDERR Dumper($location);
    my $trial_location = @{$location}[1];
    $trial_location_id = @{$location}[0];
    print "LOCATION FOR THIS TRIAL: $trial_location\n";

    # get stock names and ids (plot names) for a given trial using the trial id
    # from the stock names get the plot and block number
    # if plot and block number is not found in the plot name, generate sequence of number as plot number, use 1 as the block number and set design to CRD
    $plot_number = 1;
    my $q_2 = "select stock_id,uniquename from stock join nd_experiment_stock using(stock_id) join nd_experiment_project using (nd_experiment_id)  join nd_experiment_phenotype using (nd_experiment_id ) where project_id=? AND stock.type_id = ? " ;
    my $h_2 = $dbh->prepare($q_2);
    $h_2->execute($project_id, $plot_cvterm_id );
    
    while (my ($stock_id, $stock_name) = $h_2->fetchrow_array()) {
	
	if (my ($prefix, $plot) = ($stock_name =~ m/plot(:|_)(\d+)_/)  ) {
	    print STDERR "Matched plot number $plot in plot $stock_name\n";
	    $plot_number = $plot;
	}
	else {
	    $plot_number++;
	}
	
	if (my ($match1, $match2, $block) = ($stock_name =~ m/(replicate|)(:|_)(\d{1,2})_/) ) {
	    print STDERR "Matched block number $block in plot $stock_name\n";
	    $block_number = $block;
	}
	else {
	    $block_number = 1;
	    $trial_design = 'CRD';
	}
	push @plot_numbers_array, $plot_number;
	push @block_numbers_array, $block_number;
	push @plot_names_array, $stock_name;
	push @plot_id_array, $stock_id;
    }
    
    # get accession used in each plot for a trial
    # generate design hash for TrialDesignStore function
    for (my $n=0; $n<scalar(@plot_id_array); $n++) {
	my $q_3 = "select uniquename from stock join stock_relationship on stock_id=object_id where subject_id=? and stock.type_id=?";
	my $h_3 = $dbh->prepare($q_3);
	$h_3->execute($plot_id_array[$n],$accession_cvterm_id);
	
	while ($accession = $h_3->fetchrow_array()){
	    $design_entry{$plot_numbers_array[$n]}->{stock_name} = $accession;
	    $design_entry{$plot_numbers_array[$n]}->{plot_name} = $plot_names_array[$n];
	    $design_entry{$plot_numbers_array[$n]}->{is_a_control} = 0;
	    $design_entry{$plot_numbers_array[$n]}->{block_number} = $block_numbers_array[$n];
	    $design_entry{$plot_numbers_array[$n]}->{plot_number} = $plot_numbers_array[$n];
	}
    }
    
    print STDERR Dumper(\%design_entry);
    print "PROJECT_ID: $project_id\n";
    my $design_store = CXGN::Trial::TrialDesignStore->new({
	bcs_schema => $schema,
	trial_id => $project_id,
	design_type => $trial_design,
	design => \%design_entry,
	is_genotyping => 0,
	nd_geolocation_id => $trial_location_id,
	stocks_exist => 1
							  });
    my $validate_error = $design_store->validate_design();
    my $store_error = $design_store->store();
    if ($validate_error) {
	print STDERR "VALIDATE ERROR: $validate_error\n";
    } 
    if ($store_error) {
	print STDERR "ERROR SAVING TRIAL!: $store_error\n";
    }
    
}
