
=head1

load_cassava_snps.pl

=head1 SYNOPSIS

    $this_script.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -p project name (e.g. SNP genotyping 2012 Cornell Biotech)
 -y project year [2012]
 -g population name (e.g., NaCRRI training population) Mandatory option
 -t  Test run . Rolling back at the end.

=head2 DESCRIPTION

This script loads genotype data into the Chado genotype table
it encodes the genotype + marker name in a json format in the genotyope.uniquename field
for easy parsing by a Perl program.
The genotypes are linked to the relevant stock using nd_experiment_genotype.
each column in the spreadsheet, which represents a single accession (stock) is stored as a
single genotype entry and linked to the stock via nd_experiment_genotype.
Stock names are stored in the stock table if cannot be found, and linked to a population stock with the name supplied in opt_g

=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

July 2012

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
use Try::Tiny;
use Pod::Usage;

##

our ($opt_H, $opt_D, $opt_i, $opt_t, $opt_p, $opt_y, $opt_g);

getopts('H:i:tD:p:y:g:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;
my $population_name = $opt_g;


if (!$opt_H || !$opt_D || !$opt_i || !$opt_g) {
    pod2usage(-verbose => 2, -message => "Must provide options -H (hostname), -D (database name), -i (input file) , and -g (populations name for associating accessions in your SNP file) \n");
}

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 1,
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

my $accession_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'accession',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'accession',
    });

my $population_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
      { name   => 'training population',
	cv     => 'stock type',
	db     => 'null',
	dbxref => 'training population',
    });

 #store a project
my $project = $schema->resultset("Project::Project")->find_or_create(
    {
        name => $opt_p,
        description => $opt_p,
    } ) ;
$project->create_projectprops( { 'project year' => $opt_y }, { autocreate => 1 } );

# find the cvterm for a genotyping experiment
my $geno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'genotyping experiment',
      cv     => 'experiment type',
      db     => 'null',
      dbxref => 'genotyping experiment',
    });


# find the cvterm for the SNP calling experiment
my $snp_genotype = $schema->resultset('Cv::Cvterm')->create_with(
    { name   => 'snp genotyping',
      cv     => 'local',
      db     => 'null',
      dbxref => 'snp genotyping',
    });

my $geolocation = $schema->resultset("NaturalDiversity::NdGeolocation")->find_or_create(
    {
        description => 'Cornell Biotech', #add this as an option
    } ) ;


my $organism = $schema->resultset("Organism::Organism")->find_or_create(
    {
	genus   => 'Manihot',
	species => 'Manihot esculenta',
    } );

my $population_members = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'members of',
      cv     => 'stock relationship',
      db     => 'null',
      dbxref => 'members of',
    });

my $organism_id = $organism->organism_id();
########################

#new spreadsheet,
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);

my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();

my $coderef = sub {
    foreach my $accession_name (@columns ) {
      if ($accession_name eq "marker") {next;}
        print "Looking at accession $accession_name \n";
        my %json;
        my $cassava_stock;
        my $stock_name;
        my $stock_rs = $schema->resultset("Stock::Stock")->search(
            {
                -or => [
                     'lower(me.uniquename)' => { like => lc($accession_name) },
                     -and => [
                         'lower(type.name)'       => { like => '%synonym%' },
                         'lower(stockprops.value)' => { like => lc($accession_name) },
                     ],
                    ],
            },
            { join => { 'stockprops' => 'type'} ,
              distinct => 1
            }
            );
        if ($stock_rs->count >1 ) {
            print STDERR "ERROR: found multiple accessions for name $accession_name! \n";
            while ( my $st = $stock_rs->next) {
                print STDERR "stock name = " . $st->uniquename . "\n";
            }
            die ;
        } elsif ($stock_rs->count == 1) {
            $cassava_stock = $stock_rs->first;
            $stock_name = $cassava_stock->name;
        } else {
            #store the plant accession in the stock table
            $cassava_stock = $schema->resultset("Stock::Stock")->create(
                { organism_id => $organism_id,
                  name       => $accession_name,
                  uniquename => $accession_name,
                  type_id     => $accession_cvterm->cvterm_id,
                } );
	   
        }
	my $population_stock = $schema->resultset("Stock::Stock")->find_or_create(
            { organism_id => $organism_id,
	      name       => $population_name,
	      uniquename => $population_name,
	      type_id => $population_cvterm->cvterm_id,
            } );
	$cassava_stock->find_or_create_related('stock_relationship_objects', {
										type_id => $population_members->cvterm_id(),
										subject_id => $cassava_stock->stock_id(),
										object_id => $population_stock->stock_id(),
									       } );
	###############
        print "cassava stock name = " . $cassava_stock->name . "\n";
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
            stock_id => $cassava_stock->stock_id(),
            type_id  =>  $geno_cvterm->cvterm_id(),
                                            });

        ##################
        LABEL: foreach my $marker_name (@rows) {
            my $base_calls = $spreadsheet->value_at($marker_name, $accession_name);
	    $base_calls =~ s/\s+//;
	    next() if $base_calls !~/1|2|0|NA/i;
	    #print "Value $base_calls \n";
	    #########THESE ARE NOT MARKERS NAMES, JUST SNP identifiers.
	    ##make sure the marker name is the preffered one
            #my @ids = CXGN::Marker::Tools::marker_name_to_ids($dbh, $marker_name);
            #if (!@ids) {
            #    warn "No marker found for name $marker_name!!\n";
            #    next;
            #}
            #elsif (scalar(@ids) > 1 ) {
            #    croak "More than one id found for marker $marker_name! Please check your database and input!\n";
            #}
            #my $marker = CXGN::Marker->new($dbh, $ids[0]);
            #my $mname = $marker->get_name;
            #$json{$mname} = $base_calls;
	    $json{$marker_name} = $base_calls;
        }
        my $json_obj = JSON::Any->new;
        my $json_string = $json_obj->objToJson(\%json);
        print "Storing new genotype for stock " . $cassava_stock->name . " \n\n";
        my $genotype = $schema->resultset("Genetic::Genotype")->find_or_create(
            {
                name        => $cassava_stock->name . "|" . $experiment->nd_experiment_id,
                uniquename  => $cassava_stock->name . "|" . $experiment->nd_experiment_id,
                description => "Cassava SNP genotypes for stock $ (name = " . $cassava_stock->name . ", id = " . $cassava_stock->stock_id . ")",
                type_id     => $snp_genotype->cvterm_id,
            }
            );
        $genotype->create_genotypeprops( { 'snp genotyping' => $json_string } , {autocreate =>1 , allow_duplicate_values => 1 } );
        #link the genotype to the nd_experiment
        my $nd_experiment_genotype = $experiment->find_or_create_related('nd_experiment_genotypes', { genotype_id => $genotype->genotype_id() } );
    }
};

try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting genotyping experiments! \n\n"; }
} catch {
    # Transaction failed
    foreach my $value ( keys %seq ) {
        my $maxval= $seq{$value} || 0;
        if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
        else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};

