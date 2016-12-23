

use strict;
use Bio::Chado::Schema;

use Getopt::Std;
use CXGN::DB::InsertDBH;

use Try::Tiny;

our($opt_H, $opt_D, $opt_t);
getopts('H:D:t');
 my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$opt_H,
					  dbname=>$opt_D,
					  dbargs => {AutoCommit => 0,
						     RaiseError => 1}
					}
	);
    my $schema=Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] } );

my $coderef = sub { 
   
# Delete orphaned phenotypes that are not linked with nd_experiment 
##DO NOT RUN THIS SCRIPT IF YOU HAVE PHENOTYPES THAT ARE LINKED TO ANOTHER TABLE IN TEH DATABASE	

# Select phenotype_id FROM phenotype LEFT JOIN nd_experiment_stock USING (phenotype_id) WHERE nd_experiment_id IS NULL ; 

    
    my $phen_rs = $schema->resultset('Phenotype::Phenotype')->search( 
	{ 'nd_experiment_id' =>  \'IS NULL'   ,

	},
	{ 
	    join =>  'nd_experiment_phenotypes' ,
	} );
    my $rows = $phen_rs->count;
    print STDERR "DELETING $rows phenotype rows that have no nd_experiment_phenotype....\n\n" ;
    $phen_rs->delete() ;
    
};


try {
    $schema->txn_do($coderef);
    if (!$opt_t) { print "Transaction succeeded! Committing  \n\n"; }
    else { 
          print "TEST MODE:  Rolling back\n\n";
          $schema->txn_rollback();
    }
    $schema->txn_commit();
} catch {
    # Transaction failed
      die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};


	

	
	
