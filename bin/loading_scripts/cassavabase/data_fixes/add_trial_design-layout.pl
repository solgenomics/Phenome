#!/usr/bin/perl

=head1 NAME

add_trial_design-layout.pl - add design and layout to trials without design.
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

#opening input file and retrieving trial_names and trial_designs
open (my $file_fh, "<", $file ) || die ("\nERROR: the file $file could not be found\n" );

my $header = <$file_fh>;
while (my $line = <$file_fh>) {
		chomp $line;

		my ($trial_name,$trial_design) = split("\t", $line);
	 push @trial_names, $trial_name;
	 push @trial_designs, $trial_design;
}

my $program_object = CXGN::BreedersToolbox::Projects->new( { schema => $schema });

for (my $n=0; $n<scalar(@trial_names); $n++) {    #looping through the trial names
#foreach my $name (@trial_names){
	my $name = $trial_names[$n];
  my %design_entry;
  my $design_type = $trial_designs[$n];
  my @plot_numbers_array;
  my @block_numbers_array;
  my @plot_names_array;
  my @stock_id_array;
  my @accession_array;
	my $project_id;

	if (!$design_type){
		$design_type = 'RCBD';
	}
  print "Adding design and layout for trial: $name\n";

	my $coderef = sub {

		#getting trial id from trial name provided
		$project_id = $schema->resultset("Project::Project")->search({name => $name})->first->project_id;
    print "PROJECT_ID: $project_id\n";

		#get design cvterm_id
		my $design_cvterm_id = $schema->resultset("Cv::Cvterm")->search( {name => 'design' }, )->first->cvterm_id;
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
					value => $design_type
				});
		}else {
			print "Design $find_design found for this trial...\n";
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
		my $q_2 = "select stock_id,uniquename from stock join nd_experiment_stock using(stock_id) join nd_experiment_project using (nd_experiment_id) join project using(project_id) where project.project_id=?";
		my $h_2 = $dbh->prepare($q_2);
		$h_2->execute($project_id);

		while (my ($stock_id, $stock_name) = $h_2->fetchrow_array()) {

					if (my ($plot) = $stock_name =~ m/plot:([\d]+)_/) {
						print STDERR "Matched plot number $plot in plot $stock_name\n";
						$plot_number = $plot;
					}
          elsif (my ($plot_1) = $stock_name =~ m/plot_([\d]+)_/) {
            print STDERR "Matched plot number $plot_1 in plot $stock_name\n";
						$plot_number = $plot_1;
          }else {
            $plot_number++;
          }

					if (my ($block) = $stock_name =~ m/replicate:([\d]+)_/) {
						print STDERR "Matched block number $block in plot $stock_name\n";
						$block_number = $block;
					}
          elsif (my ($block_1) = $stock_name =~ m/_([\d])_/) {
            print STDERR "Matched block number $block_1 in plot $stock_name\n";
						$block_number = $block_1;
          }else {
            $block_number = 1;
            $design_type = 'CRD';
          }
          push @plot_numbers_array, $plot_number;
          push @block_numbers_array, $block_number;
          push @plot_names_array, $stock_name;
          push @stock_id_array, $stock_id;
      }

			# get accession used in each plot for a trial
			# generate design hash for TrialDesignStore function
      for (my $n=0; $n<scalar(@stock_id_array); $n++) {
					my $q_3 = "select uniquename from stock join stock_relationship on stock_id=object_id where subject_id=? and stock.type_id= (select cvterm_id from cv join cvterm using(cv_id) where cvterm.name='accession')";
					my $h_3 = $dbh->prepare($q_3);
					$h_3->execute($stock_id_array[$n]);

					while ($accession = $h_3->fetchrow_array()){

								$design_entry{$plot_numbers_array[$n]}->{stock_name} = $accession;
								$design_entry{$plot_numbers_array[$n]}->{plot_name} = $plot_names_array[$n];
								$design_entry{$plot_numbers_array[$n]}->{is_a_control} = 0;
								$design_entry{$plot_numbers_array[$n]}->{block_number} = $block_numbers_array[$n];
								$design_entry{$plot_numbers_array[$n]}->{plot_number} = $plot_numbers_array[$n];
      }
    }
	};

	try {
			$schema->txn_do($coderef);

	} catch {
			die "Load failed! " . $_ .  "\n" ;
	};

	print STDERR Dumper(\%design_entry);
	print "PROJECT_ID: $project_id\n";
	my $design_store = CXGN::Trial::TrialDesignStore->new({
		bcs_schema => $schema,
		trial_id => $project_id,
		design_type => $design_type,
		design => \%design_entry,
		is_genotyping => 0,
		nd_geolocation_id => $trial_location_id,
		stocks_exist => 1
	});
	my $validate_error = $design_store->validate_design();
	my $store_error;
	if ($validate_error) {
		print STDERR "VALIDATE ERROR: $validate_error\n";
	} else {
		try {
		$store_error = $design_store->store();
	} catch {
		$store_error = $_;
		};
 }
 if ($store_error) {
	print STDERR "ERROR SAVING TRIAL!: $store_error\n";
 }

}