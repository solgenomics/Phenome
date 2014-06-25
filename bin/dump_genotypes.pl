
use strict;

use Getopt::Std;
use CXGN::DB::InsertDBH;
use CXGN::Phenome::DumpGenotypes;

our ($opt_H, $opt_D, $opt_f);

getopts('H:D:f:');


my $dbh = CXGN::DB::InsertDBH->new({
    dbhost => $opt_H,
    dbname => $opt_D,
    });

my $file = $opt_f;

print STDERR "Dumping...\n";

CXGN::Phenome::DumpGenotypes::dump_genotypes($dbh, $file);

print STDERR "Done.\n";
