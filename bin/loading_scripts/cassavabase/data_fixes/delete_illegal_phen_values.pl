#!/usr/bin/perl

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
   
# Delete phenotype values that should not be stored in the database

###get rid of phenotype values that consist of spaces, tabs, dashes, dots, backticks, etc. we have 176 of those in cassavabase 
##
# DELETE FROM phenotype WHERE  phenotype_id IN (SELECT phenotype_id FROM phenotype WHERE value !~ '[0-9]'AND  value !~ '[a-z|A-Z]' ) ;

    my $phen_rs = $schema->resultset('Phenotype::Phenotype')->search( 
	{ 
	    -and => [
		 value =>  { '!~' ,  '[0-9]' }  ,
		 value =>  { '!~' ,  '[a-z|A-Z]' },
		]
	}
    );


    my $rows = $phen_rs->count;
    print STDERR "DELETING $rows phenotype rows that have non alpha-numeric values....\n\n" ;
    $phen_rs->delete() ;
  
    ###DELETE FROM phenotype WHERE value ilike '#%' ;
    #  delete phenotype rows that contain error values from the excel spreadsheet uploads
    ##
    my $phen_rs2 = $schema->resultset('Phenotype::Phenotype')->search(
	{
	    'value' => { ilike => '#%' } 
	} );
    $rows = $phen_rs2->count;
    print STDERR "DELETING $rows phenotype rows that contain excel error values...\n\n" ;
    $phen_rs2->delete() ;

    ###DELETE FROM phenotype WHERE value ilike 'CO:%' 
    #  delete phenotype rows that contain values that are the actual ontology term name, probably came from an error in the phenotyping file
    ##
    my $phen_rs3 = $schema->resultset('Phenotype::Phenotype')->search(
	{
	    'value' => { ilike => 'CO:%' } 
	} );
    $rows = $phen_rs3->count;
    print STDERR "DELETING $rows phenotype rows that contain string values of the trait name...\n\n" ;
    $phen_rs3->delete() ;
    
    ###Update phenotype values of CO:0000085 (taste of boiled roots 1-3) from string to numeric scale. Taste of boiled root rating as 1 = sweet, 2 = bland, and 3 = bitter
    #  UPDATE phenotype SET value = '1' WHERE value ilike 's' AND observable_id = (SELECT cvterm_id FROM cvterm JOIN  dbxref USING (dbxref_id) JOIN db USING (db_id) WHERE db.name = 'CO' AND dbxref.accession = '0000085') 
    #  UPDATE phenotype SET value = '2' WHERE value ilike 'bl' AND observable_id = (SELECT cvterm_id FROM cvterm JOIN  dbxref USING (dbxref_id) JOIN db USING (db_id) WHERE db.name = 'CO' AND dbxref.accession = '0000085') 
    #  UPDATE phenotype SET value = '3' WHERE value ilike 'b' AND observable_id = (SELECT cvterm_id FROM cvterm JOIN  dbxref USING (dbxref_id) JOIN db USING (db_id) WHERE db.name = 'CO' AND dbxref.accession = '0000085') 
    ##
    my $phen_rs4 = $schema->resultset('Phenotype::Phenotype')->search(
	{
	    'db.name'          => 'CO',
	    'dbxref.accession' => '0000085',
	}, 
	{ join => { observable => { 'dbxref' => 'db' } }  }, 
	);
    
    my $phen1 = $phen_rs4->search( { value => { ilike => 's' }  } );
    my $rows1 = $phen1->count;
    $phen1->update( { value => '1' } );
    print STDERR "UPDATED $rows1 phenotype rows for cvterm CO:0000085 from value = 's' to value = '1' \n\n" ;

    my $phen2 = $phen_rs4->search( { value => { ilike => 'bl' }  } );
    my $rows2 = $phen2->count;
    $phen2->update( { value => '2' } );
    print STDERR "UPDATED $rows2 phenotype rows for cvterm CO:0000085 from value = 'bl' to value = '2' \n\n" ;

    my $phen3 = $phen_rs4->search( { value => { ilike => 'b' }  } );
    my $rows3 = $phen3->count;
    $phen3->update( { value => '3' } );
    print STDERR "UPDATED $rows3 phenotype rows for cvterm CO:0000085 from value = 'b' to value = '3' \n\n" ;
    

    ##Update phenotype values of CO:0000114
    ##	boiled storage root color visual 1-3
    ##	Colour of boiled storage roots with 1 = white , 2 = cream , 3 = yellow
    ##
    # UPDATE phenotype SET value = '1' WHERE value ilike 'w' AND observable_id = (SELECT cvterm_id FROM cvterm JOIN  dbxref USING (dbxref_id) JOIN db USING (db_id) WHERE db.name = 'CO' AND dbxref.accession = '0000114') 
    #
    # UPDATE phenotype SET value = '2' WHERE value ilike 'c' AND observable_id = (SELECT cvterm_id FROM cvterm JOIN  dbxref USING (dbxref_id) JOIN db USING (db_id) WHERE db.name = 'CO' AND dbxref.accession = '0000114') 
    #
    # UPDATE phenotype SET value = '3' WHERE value ilike 'y' AND observable_id = (SELECT cvterm_id FROM cvterm JOIN  dbxref USING (dbxref_id) JOIN db USING (db_id) WHERE db.name = 'CO' AND dbxref.accession = '0000114') 
    
    my $phen_rs5 = $schema->resultset('Phenotype::Phenotype')->search(
	{
	    'db.name'          => 'CO',
	    'dbxref.accession' => '0000114',
	}, 
	{ join => { observable => { 'dbxref' => 'db' }  }  }, 
	);
    
    my $phen5 = $phen_rs5->search( { value => { ilike => 'w' }  } );
    my $rows5 = $phen5->count;
    $phen5->update( { value => '1' } );
    print STDERR "UPDATED $rows5 phenotype rows for cvterm CO:0000114 from value = 'w' to value = '1' \n\n" ;

    my $phen6 = $phen_rs5->search( { value => { ilike => 'c' }  } );
    my $rows6 = $phen6->count;
    $phen6->update( { value => '2' } );
    print STDERR "UPDATED $rows6 phenotype rows for cvterm CO:0000114 from value = 'c' to value = '2' \n\n" ;

    my $phen7 = $phen_rs5->search( { value => { ilike => 'y' }  } );
    my $rows7 = $phen7->count;
    $phen7->update( { value => '3' } );
    print STDERR "UPDATED $rows7 phenotype rows for cvterm CO:0000114 from value = 'y' to value = '3' \n\n" ;
    
    ##Delete remaining non-numeric phenotype values 
    my $phen_rs6 = $schema->resultset('Phenotype::Phenotype')->search(
	{
	    'me.value'         =>  { '!~' ,   '[0-9]' }, 
	    'db.name'          => 'CO',
	    'dbxref.accession' =>  { in => "('0000010', '0000011', '0000019', '0000085', '0000106', '0000114', '0000119')"  }  , 
	}, 
	{ join => { observable =>  { 'dbxref' => 'db' }  }  },   
	);
    my $rows8 = $phen_rs6->count;
    $phen_rs6->delete;
    print STDERR "DELETED $rows8 phenotype rows with orphaned non-numeric values \n\n" ;
    
};


try {
    $schema->txn_do($coderef);
    if (!$opt_t) { 
	print "Transaction succeeded! Committing  \n\n"; 
	$schema->txn_commit();
    } else { 
	print "TEST MODE:  Rolling back\n\n";
	$schema->txn_rollback();
    }
} catch {
    # Transaction failed
    die "An error occured! Rolling back  and reseting database sequences!" . $_ . "\n";
};


	

	
	
