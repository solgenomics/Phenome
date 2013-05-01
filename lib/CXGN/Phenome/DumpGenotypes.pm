

=head1 NAME 

CXGN::Phenome::DumpGenotypes - dump genotype info for import into HDF5 structure

=head1 AUTHOR

Lukas Mueller

=cut

package CXGN::Phenome::DumpGenotypes;

use strict;

use JSON::Any;
use Data::Dumper;

=head2 dump_genotypes

 Usage:        dump_genotypes($dbh, $outputfile)
 Desc:         dumps a matrix of all the genotypes for import to HDF5 
               data structure
 Ret:          nothing
 Args: 
 Side Effects: creates a file with the matrix info
 Example:

=cut


sub dump_genotypes { 
    my $dbh = shift;
    my $file = shift;

    my %all_keys;
    my @genotypes; 


     my $h = $dbh->prepare("SELECT stock_id, genotypeprop.value FROM nd_experiment_stock join nd_experiment_genotype USING(nd_experiment_id) JOIN genotype USING (genotype_id)  JOIN genotypeprop ON (genotype.genotype_id=genotypeprop.genotype_id) LIMIT 500");
    
    $h->execute();

    print STDERR "PROCESSING SQL...\n";

    my $count;
    while (my ($stock_id, $genotype_json) = $h->fetchrow_array()) { 
	my $genotype = JSON::Any->decode($genotype_json);
	
	push @genotypes, [$stock_id, $genotype ];
	
	#print STDERR Data::Dumper::Dumper($genotype);
	print STDERR "$count\r";
	$count++;
	foreach my $k (keys %$genotype) { 
	    $all_keys{$k}++;
	 #   print STDERR "Adding key $k\n";
	}
    }
    my $matrix = ""; 
    
    foreach my $k (keys %all_keys) { 
	# print header row
	$matrix .= "\t".$k;
    }

    $matrix .= "\n";
    $count = 0;
    foreach my $g (@genotypes) { 

	$matrix .= $g->[0];

	if ($count %100 == 0) { 
	    print STDERR "Processing $count\r";
	}

	print STDERR "Adding $g->[0]...\n";

	foreach my $k (keys %all_keys) { 
	    # print header row
	    $matrix .= "\t".$g->[1]->{$k};
	    #print STDERR "ADDING ".$g->[1]->{$k}."\r";
	}	
	$matrix .= "\n";

    }
	
    print "WRITING FILE... (".(length($matrix))." bytes)\n";

    open (my $F, ">", $file) || die "Can't open file $file\n";
    print $F $matrix;
    close($F);

}

1;
