

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

    my $BATCH_SIZE = 50;
    # first, get all the marker names in the dataset
    #


    my $q = "";
    my $h;
    my %markers;
    my $count;

    $q = "SELECT count(*) from public.genotypeprop";
    $h = $dbh->prepare($q);
    $h->execute();
    my ($genotype_count) = $h->fetchrow_array();

    print STDERR "Genotype count: $genotype_count\n";

    foreach my $batch (1..(int($genotype_count/$BATCH_SIZE)+1)) { 
	
	my $batch_start = $BATCH_SIZE * ($batch -1) +1;

	print STDERR "PROCESSING BATCH $batch_start ... ($BATCH_SIZE)\n";
	
	$q = "SELECT stock_id, genotypeprop.value FROM public.nd_experiment_stock join public.nd_experiment_genotype USING(nd_experiment_id) JOIN public.genotype USING (genotype_id)  JOIN public.genotypeprop ON (genotype.genotype_id=genotypeprop.genotype_id) order by nd_experiment_stock.stock_id OFFSET ? LIMIT ?";


	$h = $dbh->prepare($q);
	
	$h->execute($batch_start, $BATCH_SIZE);
	
	print STDERR "PROCESSING SQL...\n";
	
	my $count;
	
	while (my ($stock_id, $genotype_json) = $h->fetchrow_array()) { 
	    
	    my $genotype = JSON::Any->decode($genotype_json);
	    
	    print STDERR "Genotype for stock_id $stock_id...\n";
	    
#	print STDERR Dumper($genotype);
	    
	    foreach my $k (keys(%$genotype)) {
		$markers{$k}++;
	    }
	    
	}
	
	print "Total markers: ".scalar(keys(%markers))."\n";
	
    }

    open (my $F, ">", $file) || die "Can't open file $file\n";

    foreach my $batch (1..(int($genotype_count/$BATCH_SIZE)+1)) { 
	
	my $batch_start = $BATCH_SIZE * ($batch -1) +1;

	print STDERR "PROCESSING BATCH $batch_start ... ($BATCH_SIZE)\n";
    
	my $matrix_line = "";
	
	foreach my $k (keys %markers) { 
	    # print header row
	    $matrix_line .= "\t".$k;
	}
	

	
	print $F "$matrix_line\n";
	
	
	$h = $dbh->prepare($q);
	

	$h->execute($batch_start, $BATCH_SIZE);
	
	print STDERR "PROCESSING SQL...\n";
	
	$count = 0;
	
	while (my ($stock_id, $genotype_json) = $h->fetchrow_array()) { 
	    my $genotype = JSON::Any->decode($genotype_json);
	    $matrix_line = "";
	    
	    $matrix_line = $stock_id;
	    
	    if ($count %100 == 0) { 
		print STDERR "Processing $count\r";
	    }

	    print STDERR "Adding $stock_id...\n";
	    
	    foreach my $k (keys %markers) { 
		# print header row
		$matrix_line .= "\t".$genotype->{$k};
		#print STDERR "ADDING ".$g->[1]->{$k}."\r";
	    }	
	    $matrix_line .= "\n";
	    
	    print  $F $matrix_line;
	}
	
	close($F);

    }
    $dbh->disconnect();
}


1;
