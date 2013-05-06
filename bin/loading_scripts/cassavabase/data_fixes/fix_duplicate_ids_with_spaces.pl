

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
   


	

					      
    my $tmeb_space_rs = $schema->resultset('Stock::Stock')->search( { name => { ilike => 'TMEB %' }});
    my $not_found=0;
    while (my $old_stock = $tmeb_space_rs->next()) { 
	
	my $old_stock_id = $old_stock->stock_id();

	my $old_stock_name = $old_stock->name();

	my $new_stock_name = $old_stock_name;
	$new_stock_name =~ s/ //g;
	my $new_stock = $schema->resultset('Stock::Stock')->search( { name => $new_stock_name } )->first();
	

	print STDERR "OLD STOCK: $old_stock_name.\n";

	if (!$new_stock) { 
	    print "NOT FOUND: $new_stock_name. SKIPPING!\n";
	    $not_found++;
	    next;
	}
	
	print STDERR "FOUND NEW STOCK: $new_stock_name .\n";

	

	# we are going to change  nd_experiment_stock, and stock_relationship to the corresponding id
        # of the new_stock.  

	# and then we will change to name to the name without a space, delete the other stock_owner entry,
	# and then we will delete the other stock. 
	# 
	

	

	#my $nd_experiment_stocks_rs = $old_stock->nd_experiment_stocks();

	#$nd_experiment_stocks_rs->update( { stock_id => $new_stock->stock_id });
	#print STDERR "OLD STOCK: ".$old_stock->stock_id." NEW STOCK: ".$new_stock->stock_id()."\n";
	



	my $parent_stocks_rs = $old_stock->stock_relationship_objects();	

	while (my $parent_stock = $parent_stocks_rs->next()) { 
	    my $existing_parent = $new_stock->stock_relationship_objects( { object_id => $parent_stock->object_id, type_id=>$parent_stock->type_id, rank=>$parent_stock->rank() });
	    
	   
	    if (!$existing_parent->count()) { 
		print STDERR "Updating stock relationships from stock $old_stock_id to ".$new_stock->stock_id."\n";
		$parent_stock->update( { object_id => $new_stock->stock_id });
	    }
	}

	my $child_stocks_rs = $old_stock->stock_relationship_subjects();


	while (my $child_stock = $child_stocks_rs->next()) { 
	    my $existing_child = $new_stock->stock_relationship_subjects( { object_id => $child_stock->object_id, type_id=>$child_stock->type_id, rank=>$child_stock->rank()  });

	    if ($existing_child->count() > 0) { 

		print STDERR "Updating stock relationships from stock $old_stock_id to ".$new_stock->stock_id."\n";
		$child_stock->update( { subject_id => $new_stock->stock_id });
	    }
	}   
	


	#my $q = "DELETE FROM phenome.stock_owner WHERE stock_id=?";
	#my $h = $dbh->prepare($q);
	#$h->execute($old_stock_id);
	
	
	#$old_stock->delete();

    }
};


try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting stocks and their properties! \n\n"; }
} catch {
    # Transaction failed
      die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};


	

	
	
