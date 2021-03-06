
=head1 NAME

stock_synonyms.pl - add synonyms for stocks

=head1 DESCRIPTION

Adds synonyms for stocks. The stocks must already be in the database and match the uniquename supplied. The synonym must not be in the database at all, otherwise it is not stored again.

Typical usage:

stock_synonyms.pl tab_separated_file_of_stocknames_and_synonyms

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=cut

use strict;

use Getopt::Std;
use CXGN::DB::InsertDBH;

our ($opt_D, $opt_H);

getopts('H:D:');
my $dbh = CXGN::DB::InsertDBH->new({ 
    dbhost => $opt_H,
    dbname => $opt_D,
    });

my $file = shift;

open (my $F, "<", $file) || die "Can't open file $file.";
while (<$F>) { 
    chomp;
    my ($stock_name, $synonym) = split "\t";

    if ($stock_name eq $synonym) { 
	print STDERR "Stock name $stock_name and synonym $synonym are identical. Skipping.\n";
	next;
    }

    my $q = "SELECT stock_id FROM stock where name=?";
    my $h = $dbh->prepare($q);
    $h->execute($stock_name);

    my ($stock_id) = $h->fetchrow_array();
    if (!$stock_id) { 

	my $q = "SELECT stock_id FROM stock JOIN stockprop using(stock_id)  JOIN cvterm on (stockprop.type_id=cvterm_id) WHERE (cvterm.name='synonym') and stockprop.value=?";
	my $h = $dbh->prepare($q);
	$h->execute($stock_name);
	my @stocks = ();
	($stock_id) = $h->fetchrow_array(); # uniquename must be unique
    }

  
  

    if (!$stock_id) { 
	print STDERR "The stock $stock_name is not found in the database. Skipping.\n";
	next;
    }
  
    print STDERR "FOUND STOCK ID $stock_id stock name $stock_name\n";  

    # does the synonym already exist?
    #
    my $q2 = "SELECT value from stockprop WHERE value=?";
    my $h2 = $dbh->prepare($q2);
    $h2->execute($synonym);

    my ($existing_synonym) = $h2->fetchrow_array();

    if ($existing_synonym) { 
	print STDERR "Synonym $synonym already exists in the database. Skipping.\n";
	next;
    }

    my $q3 = "SELECT cvterm_id FROM cvterm JOIN cv using(cv_id) WHERE cv.name='local' and cvterm.name = 'synonym'";
    my $h3 = $dbh->prepare($q3);

    $h3->execute();

    my ($synonym_type_id) = $h3->fetchrow_array();


    # get rank and increase it if necessary.
    $q = "SELECT max(rank) FROM stockprop where stock_id=? and type_id=?";
    $h = $dbh->prepare($q);
    $h->execute($stock_id, $synonym_type_id);
    my ($rank) = $h->fetchrow_array();

    if (!defined($rank)) { $rank = 0; }
    else { 
	$rank++;
    }

    print STDERR "Inserting synonym $synonym for $stock_name, $stock_id\n";

    my $q4 = "INSERT INTO stockprop (stock_id, type_id, value, rank) VALUES (?, ?, ?, ?)";
    my $h4 =  $dbh->prepare($q4);
    $h4->execute($stock_id, $synonym_type_id, $synonym, $rank);
 

}

$dbh->commit();

close ($F);

print STDERR "DONE!\n";    
