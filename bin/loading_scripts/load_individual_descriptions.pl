

use strict;

use Getopt::Std;

use CXGN::DB::InsertDBH;
use CXGN::Phenome::Individual;

our ($opt_D, $opt_H);

getopts('D:H:');

my $dbh = CXGN::DB::InsertDBH->new({dbname=>$opt_D,
				    dbhost=>$opt_H,
				    dbuser=>"postgres",
				});


my $file = shift;

open (F, "<$file") || die "Can't open file $file.\n";

my @not_found = ();

eval { 
    while (<F>) { 
    chomp;
    my ($accession, $shape, $size, $perimeter, $area, $origin, $seed_source, $type) = split /\t/;
    
    my ($ind) = CXGN::Phenome::Individual->new_with_name($dbh, $accession);

    if (!$ind) { 
	print STDERR "Accession $accession not found. Skipping...\n";
	push @not_found, $accession;
	next();
    }
    
    print STDERR "Processing $accession...\n";
    my $description = "";
    
    if ($size) { 
	$description .= "Fruits are of $size size ";
    }
    if ($shape) { 
	$shape =~ tr/A-Z/a-z/;
	$description .= "and $shape in shape. ";
    }
    else { 
	$description .= ". ";
    }


    if ($origin) { 
	$description .= "The country of origin is $origin. ";
    }
    if ($seed_source) { 
	$seed_source =~ s/(.*)\.$/$1/;
	$description .= "Seeds were obtained from $seed_source. ";
    }
    if ($type) { 
	$description .= "This accession belongs to the '$type' varieties. ";
    }

    $ind->set_description($description);

    print STDERR "$accession\t$description\n";

    my $ind_id = $ind->store();
    print STDERR "Stored description for individual $accession\n";

}
};

if ($@) { 
    print STDERR "Error: $@\n";
    $dbh->rollback();
}
else { 
    print STDERR "Committing...\n";
    $dbh->commit();
}
    

print STDERR "Not found: \n";
foreach my $a (@not_found) { 
    print "$a\n";
}
print STDERR "Done.\n";
