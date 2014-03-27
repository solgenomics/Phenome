

use strict;
use Bio::Chado::Schema;

use Getopt::Std;
use CXGN::DB::InsertDBH;

use Try::Tiny;

our($opt_H, $opt_D, $opt_t);
getopts('H:D:t');
 my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$opt_H,
					  dbname=>$opt_D,
					  dbargs => {AutoCommit => 1,
						     RaiseError => 1}
					}
	);
    my $schema=Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] } );

my $coderef = sub { 
   
# update stock names that have a synonym of IITA- .... the synonym should be the preferred name, and the old synonym name/uniquename should be the synonym now: 
	

# select stock.stock_id, stock.uniquename, stock.name, value from stockprop join stock using (stock_id) join cvterm on cvterm_id = stockprop.type_id where value ilike 'IITA%' and cvterm.name ilike 'synonym'

    
    my $iita_rs = $schema->resultset('Stock::Stock')->search( 
	{ 'type.name' => { ilike => '%synonym%' },
	  'stockprops.value' => { ilike => 'IITA%' }
	},
	{ 
	
	    select => [ qw / me.stock_id uniquename stockprops.value  stockprops.stockprop_id / ],
	    as     => [ qw / stock_id uniquename synonym stockprop_id / ],
	    join =>  { stockprops => 'type' } ,
	} );
    while (my $iita_stock = $iita_rs->next()) { 
	
	my $stock_uniquename = $iita_stock->uniquename;
	my $stock_synonym = $iita_stock->get_column('synonym');

	if ($stock_uniquename ne $stock_synonym ) { #make the synonym the uniquename and the uniquename the synonym 
	    #check if the uniquename exists 
	    my $existing_stock = $schema->resultset('Stock::Stock')->find( 
		{ uniquename => $stock_synonym }
		);
	    if ($existing_stock) {
		print STDERR "Stock $stock_uniquename already exists ! Cannot update! \n";
		next();
	    }
	    print STDERR "Changing uniquename $stock_uniquename to synonym $stock_synonym\n";
	    $iita_stock->update( { uniquename => $stock_synonym } ) ;
	    
	    my $stockprop = $schema->resultset('Stock::Stockprop')->find( { stockprop_id => $iita_stock->get_column('stockprop_id') } );
	    #print STDERR "Updating stockprop value $stock_synonym to $stock_uniquename\n";
	    $stockprop->update( { value => $stock_uniquename } ) ;
	}
    }
};


try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting stock uniquenames and their synonyms! \n\n"; }
} catch {
    # Transaction failed
      die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};


	

	
	
