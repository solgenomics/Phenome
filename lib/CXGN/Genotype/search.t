
use strict;
use warnings;

use Test::More;
use CXGN::DB::Connection;
use CXGN::Genotype::Search;
use Bio::Chado::Schema;

my $dbh = CXGN::DB::Connection->new( { dbhost=>'localhost',
				       dbname=>'sandbox',
				       dbuser=>'postgres',
				       dbpass=>'Eise!Th9',
				     }
    );

my $schema = Bio::Chado::Schema->connect( sub { $dbh->get_actual_dbh });


my $s = CXGN::Genotype::Search->new({ dbh=>$dbh, schema=>$schema });

print "Genotype by stock id:\n";

print $s->genotype_by_stock_id(145);



print STDERR "Starting query... ";
my @results = $s->genotype_by_marker('solcap_snp_sl_8527');

print STDERR "Done.\n";

print "Returned ".(scalar(@results))." lines: \n";

foreach my $r (@results) { 
    print "$r->[0], $r->[1], $r->[2]\n";
}



