

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
   


	

					      
    my $nr_backs_rs = $schema->resultset('Stock::Stock')->search( { name => { ilike => 'NR11\\\\%' }});
    my $not_found=0;
    while (my $old_stock = $nr_backs_rs->next()) { 
	
	my $old_stock_id = $old_stock->stock_id();

	my $old_stock_name = $old_stock->name();

	my $new_stock_name = $old_stock_name;
	$new_stock_name =~ s/\\//g;
	my $new_stock = $schema->resultset('Stock::Stock')->search( { name => $new_stock_name } )->first();

	print STDERR "OLD STOCK: $old_stock_name. id = $old_stock_id \n";

	if (!$new_stock) { 
	    print "NOT FOUND: $new_stock_name. UPDATING name of $old_stock_name!\n";
	    $not_found++;
	    $old_stock->update( { name => $new_stock_name , uniquename => $new_stock_name } );
	    next;
	}
	my $new_stock_id = $new_stock->stock_id;
	print STDERR "FOUND NEW STOCK: $new_stock_name . id = $new_stock_id \n";

	# we are going to change  nd_experiment_stock, and stock_relationship to the corresponding id
        # of the new_stock.  
	# and then we will change to name to the name without a space, delete the old stock_owner entry,
	# and then we will delete the old stock. 
	# 
	
	#no need to do this since the stocks linked to experiments are the plots. 
	#changing the stock_relationship will take care of this . (plots will be now subjects of the new stock).
	#my $nd_experiment_stocks_rs = $old_stock->nd_experiment_stocks();
	#$nd_experiment_stocks_rs->update( { stock_id => $new_stock->stock_id });
	#print STDERR "OLD STOCK: ".$old_stock->stock_id." NEW STOCK: ".$new_stock->stock_id()."\n";
	

	my $parent_stockrel_rs = $old_stock->stock_relationship_objects();	

	while (my $parent_stockrel = $parent_stockrel_rs->next()) { 
	    #check if the new stock is already a subject of this parent

	    my $existing_parent = $new_stock->stock_relationship_objects( { subject_id => $parent_stockrel->subject_id, type_id=>$parent_stockrel->type_id, rank=>$parent_stockrel->rank() });
	    
	   
	    if (!$existing_parent->first) { 
		print STDERR "Updating stock relationships " . $parent_stockrel->stock_relationship_id . " from subject  $old_stock_id to ".$new_stock->stock_id."\n";
		
		$parent_stockrel->update( { object_id => $new_stock->stock_id });
	    }
	}

	my $child_stockrel_rs = $old_stock->stock_relationship_subjects();

	while (my $child_stockrel = $child_stockrel_rs->next()) { 
	    my $existing_child = $new_stock->stock_relationship_subjects( { object_id => $child_stockrel->object_id, type_id=>$child_stockrel->type_id, rank=>$child_stockrel->rank()  });

	    if (!$existing_child->first ) { 

		print STDERR "Updating stock relationships from object $old_stock_id to ".$new_stock->stock_id."\n";
		$child_stockrel->update( { subject_id => $new_stock->stock_id });
	    }
	}   
	
	my $q = "DELETE FROM phenome.stock_owner WHERE stock_id=?";
	my $h = $dbh->prepare($q);
	$h->execute($old_stock_id);
	print STDERR "***DELETING old stock $old_stock_name\n";
	$old_stock->delete();
    }
    if ($opt_t) { die "TEST RUN! rolling back! \n\n"; } 
};


try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Commiting stocks and their properties! \n\n"; }
} catch {
    # Transaction failed
      die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};


	

	
	
