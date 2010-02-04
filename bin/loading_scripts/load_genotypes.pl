

use strict;

use Getopt::Std;
use CXGN::DB::InsertDBH;
use CXGN::Marker;
use CXGN::Phenome::Genotype;
use CXGN::Phenome::GenotypeRegion;
use CXGN::Phenome::GenotypeExperiment;
use CXGN::Phenome::Individual;
use CXGN::Cview::Map::Tools;
use CXGN::Marker::Tools;

our ($opt_D, $opt_H, $opt_s, $opt_m, $opt_b, $opt_p);

getopts('D:H:s:m:b:p:');

if (!$opt_p) { 
    print STDERR " -p population_id is required. Stop.\n";
    exit();
}

if (!$opt_s) { 
    $opt_s = "206";
    print STDERR "no -s specified. Using default of 206.\n";
}
my $sp_person_id=$opt_s;

if (!$opt_m) { 
   $opt_m = 17;
   print STDERR "Using a default of $opt_m for the reference map id.\n";
}
my $reference_map_id=$opt_m;

if (!$opt_b) { 
    $opt_b = 100;
    print STDERR "Using a default background accession id of $opt_b.\n"; 
}
my $background_accession_id=$opt_b;

my $file = shift;

my $dbh = CXGN::DB::InsertDBH->new({ dbname=>$opt_D,
				     dbhost=>$opt_H,
				     dbuser=>"postgres"
				     });

if (!$file) { 
    print <<TEXT;

Usage: load_genotypes.pl -H host -D dbname [-s sp_person_id] file\n

TEXT

    exit();
}

my $map_version_id = CXGN::Cview::Map::Tools::find_current_version($dbh, $reference_map_id);

open(F, "<$file") || die "Can't open file '$file'\n";

#my $first_line = (<F>); # throw away, contains chr info
my $header = (<F>);
chomp($header);

my (undef, @markers) = split /\t/, $header;

print STDERR  "Markers @markers\n";


eval { 
    my $experiment = CXGN::Phenome::GenotypeExperiment->new($dbh);
    
    $experiment->set_background_accession_id($background_accession_id);
    $experiment->set_experiment_name("QTL experiment");
    $experiment->set_reference_map_id($reference_map_id);
    $experiment->set_sp_person_id($sp_person_id);
    $experiment->set_preferred(1);
    my $experiment_id = $experiment->store();
    

    while (<F>) { 
	chomp;
	my ($individual_name, @scores) = split /\t/;
	print STDERR "Processing individual $individual_name...\n";
	my (@individuals) = CXGN::Phenome::Individual->new_with_name($dbh, $individual_name);
	
	if (@individuals>1) { 
	    print STDERR "Found several individuals with name $individual_name. Skipping.\n";
	    next();
	}
	my $individual = $individuals[0];
	
	if ($individual && $individual->get_population_id() != $opt_p) { 
	    print STDERR "Individual $individual_name is not from population $opt_p\n";
	    exit();
	}


	if (!$individual) { 
	    print STDERR "Individual $individual_name not found. \n";
	    
	    print STDERR "Can't continue without individual $individual_name\n";
	    print STDERR "Insert individual? Give population id or type N:";
	    my $response = <STDIN>;
	    chomp($response);
	    if ($response=~/n/i) { next(); }
	    
	    else { 
		
		print STDERR "Creating new individual...\n";
		$individual=CXGN::Phenome::Individual->new($dbh);
		$individual->set_name($individual_name);
		$individual->set_population_id($opt_p); #!!!!!!!!!!!
		my $individual_id = $individual->store();
		
		print STDERR "Inserted Individual $individual_name with id $individual_id\n";
	    }
	    
	}

	
	
	my $genotype = CXGN::Phenome::Genotype->new($dbh);
	
	print STDERR "experiment_id is $experiment_id\n";
	$genotype->set_genotype_experiment_id($experiment_id);
	$genotype->set_individual_id($individual->get_individual_id());
	

	my $genotype_id = $genotype->store();
	
	for(my $i=0; $i<@scores; $i++) { 
	    my $genotype_region = CXGN::Phenome::GenotypeRegion->new($dbh);
	    
	    my $clean_name = $markers[$i];
	    $clean_name=~s/\*//g;
	    $clean_name=~s/^ *(.*) *$/$1/; #clean leading/trailing spaces
	    $clean_name = CXGN::Marker::Tools::clean_marker_name($clean_name);
	    my $marker = CXGN::Marker->new_with_name($dbh, $clean_name);

	    if (!$scores[$i] || ($scores[$i] =~/\-/)) { 
		print STDERR "No zygocity information ($scores[$i]). Skipping...\n";
		next();
	    }

	    if (!$marker) { 
		print STDERR "Marker $clean_name not found. Skipping...\n";
		next();
	    }
	    
	    my $experiments = $marker->experiments();
	    my $lg_id = 0;
	    foreach my $e (@$experiments) { 
		if (defined($e->{location})) { 
		    
		    if ($e->{location}->map_version_id() eq $map_version_id) { 
			#print STDERR "Defined location for marker $markers[$i] on map $map_version_id...\n";		    
			$lg_id = $e->{location}->lg_id();
		    }
		}
	    }
	    
	    if (!$lg_id) { 
		print STDERR "Marker $markers[$i] has no mapped locations on map version $map_version_id. Inserting undef for lg_id \n";
		
		$lg_id = undef;
	    }
	    $genotype_region->set_genotype_id($genotype_id);
	    $genotype_region->set_marker_id_nn($marker->marker_id());
	    $genotype_region->set_marker_id_ns($marker->marker_id());
	    $genotype_region->set_marker_id_sn($marker->marker_id());
	    $genotype_region->set_marker_id_ss($marker->marker_id());
	    $genotype_region->set_lg_id($lg_id);
	    print STDERR "Setting score: $scores[$i]\n";
	    $genotype_region->set_mapmaker_zygocity_code($scores[$i]);
	    
	    $genotype_region->set_type("map");
	    
	    $genotype_region->store();
	    
	}
    }
    
};

if ($@) { 
    $dbh->rollback();
    print STDERR "An error occurred: $@. ROLLED BACK CHANGES.\n";
}
else { 
    print STDERR "All fine. Committing...\n";
    $dbh->commit();
}
print STDERR "Done.\n";
