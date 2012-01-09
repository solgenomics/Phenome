
=head1

load_solcap_genotypes.pl

=head1 SYNOPSIS

    $this_script.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.

=head2 DESCRIPTION

This script loads genotype data into the Chado genotype table
it encodes the genotype + marker name in a json format in the genotyope.uniquename field
for easy parsing by a Perl program.
The genotypes are linked to the relevant stock using nd_experiment_genotype.
each column in the spreadsheet, which represents a single accession (stock) is stored as a
single genotyep entry and linked to the stock via nd_experiment_genotype.

=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

December 2011

=cut


#!/usr/bin/perl
use strict;

use Getopt::Std;
use CXGN::Tools::File::Spreadsheet;
use JSON::Any;
use Bio::Chado::Schema;
use CXGN::People::Person;
use CXGN::Marker;
use CXGN::Marker::Tools;

use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;

##

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
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } );
$dbh->do('SET search_path TO public,sgn');

#getting the last database ids for resetting at the end in case of rolling back
###############
my $last_nd_experiment_id = $schema->resultset('NaturalDiversity::NdExperiment')->get_column('nd_experiment_id')->max;
my $last_cvterm_id = $schema->resultset('Cv::Cvterm')->get_column('cvterm_id')->max;
my $last_nd_experiment_project_id = $schema->resultset('NaturalDiversity::NdExperimentProject')->get_column('nd_experiment_project_id')->max;
my $last_nd_experiment_stock_id = $schema->resultset('NaturalDiversity::NdExperimentStock')->get_column('nd_experiment_stock_id')->max;
my $last_nd_experiment_genotype_id = $schema->resultset('NaturalDiversity::NdExperimentGenotype')->get_column('nd_experiment_genotype_id')->max;
my $last_genotype_id = $schema->resultset('Genetic::Genotype')->get_column('genotype_id')->max;
my $last_project_id = $schema->resultset('Project::Project')->get_column('project_id')->max;

my %seq  = (
    'nd_experiment_nd_experiment_id_seq' => $last_nd_experiment_id,
    'cvterm_cvterm_id_seq' => $last_cvterm_id,
    'nd_experiment_project_nd_experiment_project_id_seq' => $last_nd_experiment_project_id,
    'nd_experiment_stock_nd_experiment_stock_id_seq' => $last_nd_experiment_stock_id,
    'nd_experiment_genotype_nd_experiment_genotype_id_seq' => $last_nd_experiment_genotype_id,
    'genotype_genotype_id_seq' => $last_genotype_id,
    'project_project_id_seq'   => $last_project_id,
    );

 #store a project
my $project = $schema->resultset("Project::Project")->find_or_create(
    {
        name => "Solcap processing tomatoes genotyping Infinium array 2011",
        description => "Solcap processing tomatoes scored for >8,000 SNP markers 2011",
    } ) ;
$project->create_projectprops( { 'project year' => '2011' }, { autocreate => 1 } );

# find the cvterm for a genotyping experiment
my $geno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'genotyping experiment',
      cv     => 'experiment type',
      db     => 'null',
      dbxref => 'genotyping experiment',
    });

# find the cvterm for a Infinium array
my $infinium_array = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'Infinium array',
      cv     => 'local',
      db     => 'null',
      dbxref => 'Infinium array',
    });

my $username = 'solcap_project';
my $sp_person_id= CXGN::People::Person->get_person_by_username($dbh, $username);

die "User $username for Solcap must be pre-loaded in the database! \n" if !$sp_person_id ;

my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create(
    {
        description => 'UC Davis sequencing facility',
    } ) ;
########################

#new spreadsheet, skip 2 first columns
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file, 2);

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

eval {
    foreach my $solcap_number (@columns ) {
        print "Looking at solcap number $solcap_number \n";
        my %json;
        my $solcap_stock = $schema->resultset('Stock::Stockprop')->search(
            {
                'me.value'  => $solcap_number,
                'type.name' => 'solcap number',
            },
            { join => 'type' } , )->search_related('stock')->first;
        if (!$solcap_stock) { warn("No stock found for solcap $solcap_number !!!\n"); next; }
        print "Solcap stock name = " . $solcap_stock->name . "\n";
        my $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->create(
            {
                nd_geolocation_id => $geolocation->nd_geolocation_id(),
                type_id => $geno_cvterm->cvterm_id(),
            } );
        #link to the project
        $experiment->find_or_create_related('nd_experiment_projects', {
            project_id => $project->project_id()
                                            } );
        #link the experiment to the stock
        $experiment->find_or_create_related('nd_experiment_stocks' , {
            stock_id => $solcap_stock->stock_id(),
            type_id  =>  $geno_cvterm->cvterm_id(),
                                            });
        ##################
        LABEL: foreach my $marker_name (@rows) {
            my $base_calls = $spreadsheet->value_at($marker_name, $solcap_number);
	    $base_calls =~ s/\s+//;
	    #print "Value $value \n";
	    next() if $base_calls !~ /A|T|C|G/i;
            ##make sure the marker name is the preffered one (the solcap identifier)

            my @ids = CXGN::Marker::Tools::marker_name_to_ids($dbh, $marker_name);
            if (!@ids) {
                warn "No marker found for name $marker_name!!\n";
                next;
            }
            elsif (scalar(@ids) > 1 ) {
                croak "More than one id found for marker $marker_name! Please check your database and input!\n";
            }
            my $marker = CXGN::Marker->new($dbh, $ids[0]);
            my $mname = $marker->get_name;
            $json{$mname} = $base_calls;
        }
        my $json_obj = JSON::Any->new;
        my $json_string = $json_obj->objToJson(\%json);
        print "Storing new genotype for stock " . $solcap_stock->name . " \n\n";
        my $genotype = $schema->resultset("Genetic::Genotype")->find_or_create(
            {
                name        => $solcap_stock->name . "|" . $experiment->nd_experiment_id,
                uniquename  => $solcap_stock->name . "|" . $experiment->nd_experiment_id,
                description => "Solcap Infinium array genotypes for stock $solcap_number (name = " . $solcap_stock->name . ", id = " . $solcap_stock->stock_id . ")",
                type_id     => $infinium_array->cvterm_id,
            }
            );
        $genotype->create_genotypeprops( { 'infinium array' => $json_string } , {autocreate =>1 , allow_duplicate_values => 1 } );
        #link the genotype to the nd_experiment
        my $nd_experiment_genotype = $experiment->find_or_create_related('nd_experiment_genotypes', { genotype_id => $genotype->genotype_id() } );
    }
};


if ($@) { print "An error occured! Rolling backl!\n\n $@ \n\n "; }
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    foreach my $value ( keys %seq ) {
	my $maxval= $seq{$value} || 0;
	if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
}else {
    print "Transaction succeeded! Commiting ! \n\n";
    $dbh->commit();
}
