
=head1

load_solcap_plots.pl

=head1 SYNOPSIS

    thisScript.pl  -H [dbhost] -D [dbname] -i inFile [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name 
 -D  database name 
 -i infile 
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION



Naama Menda (nm249@cornell.edu)

    August 2010
 
=cut


#!/usr/bin/perl
use strict;
use Getopt::Std; 
use CXGN::Tools::File::Spreadsheet;

use CXGN::Phenome::Schema;
use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;


use CXGN::Chado::Dbxref;
use CXGN::Chado::Phenotype;
use CXGN::People::Person;

our ($opt_H, $opt_D, $opt_i, $opt_t);

getopts('H:i:tD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $file = $opt_i;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				    }
    );
my $schema= Bio::Chado::Schema->connect(  sub { $dbh->get_actual_dbh() } ,  { on_connect_do => ['SET search_path TO  public;'] }
					  );

#getting the last database ids for resetting at the end in case of rolling back
my $last_stockprop_id= $schema->resultset('Stock::Stockprop')->get_column('stockprop_id')->max; 
my $last_stock_id= $schema->resultset('Stock::Stock')->get_column('stock_id')->max;
my $last_stockrel_id= $schema->resultset('Stock::StockRelationship')->get_column('stock_relationship_id')->max; 
my $last_cvterm_id= $schema->resultset('Cv::Cvterm')->get_column('cvterm_id')->max; 
my $last_cv_id= $schema->resultset('Cv::Cv')->get_column('cv_id')->max; 
my $last_db_id= $schema->resultset('General::Db')->get_column('db_id')->max; 
my $last_dbxref_id= $schema->resultset('General::Dbxref')->get_column('dbxref_id')->max; 
my $last_organism_id = $schema->resultset('Organism::Organism')->get_column('organism_id')->max;

my %seq  = (
	    'db_db_id_seq' => $last_db_id,
	    'dbxref_dbxref_id_seq' => $last_dbxref_id,
	    'cv_cv_id_seq' => $last_cv_id,
	    'cvterm_cvterm_id_seq' => $last_cvterm_id,
	    'stock_stock_id_seq' => $last_stock_id,
	    'stockprop_stockprop_id_seq' => $last_stockprop_id,
	    'stock_relationship_stock_relationship_id_seq' => $last_stockrel_id,
	    'organism_organism_id_seq' => $last_organism_id,
	    );

#new spreadsheet
my $spreadsheet=CXGN::Tools::File::Spreadsheet->new($file);

##############
##parse first the file with the accessions . Load it into phenome.individual and public.stock
#############



my $sp_person_id = CXGN::People::Person->get_person_by_username($dbh, 'solcap_project');
die "Need to have SolCAP user pre-loaded in the sgn database! " if !$sp_person_id;

 
my $organism = $schema->resultset("Organism::Organism")->find_or_create( {
    species => 'any' } );
my $organism_id = $organism->organism_id();

## For the stock module:

#the cvterm for plots
print "Finding/creating cvterm for population\n";
my $plot_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'plot',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'plot',
    });

################################

print "parsing spreadsheet... \n";
my @rows = $spreadsheet->row_labels();
my @columns = $spreadsheet->column_labels();


eval {
    foreach my $plot (@rows ) { 
	print "label is $plot \n\n";
	my $sct = $spreadsheet->value_at($plot, 'SCT#');
	#find the stock for the sct#
	my ($parent_stock) = $schema->resultset("Cv::Cvterm")->search( {
	    'me.name' => 'solcap number' } )->search_related('stockprops', { 
		value => $sct } )->search_related('stock');
	die "No stock found for sct# $sct. Check your database! \n" if !$parent_stock ;
	
	my $year = $spreadsheet->value_at($plot, 'Year');
	my $loc1 = $spreadsheet->value_at($plot, 'Location');
	my $loc2 = $spreadsheet->value_at($plot, 'Location2');
	my $location = "$loc1, $loc2";
	

	my $rep = $spreadsheet->value_at($plot, 'Replicate');

		
	my $stock = $schema->resultset("Stock::Stock")->find_or_create( 
	    { organism_id => $parent_stock->organism_id(),
	      name  => $plot,
	      uniquename => $plot ."_" . $rep . "_" . $year.",". $location,
	      type_id => $plot_cvterm->cvterm_id(),
	    });
	    
	
	#add the owner for this stock
	$stock->create_stockprops( { sp_person_id => $sp_person_id }, { autocreate => 1 , cv_name => 'local'} );
	
	##
        #add new stock_relationship
	#the cvterm for the relationship type 
	print "Finding/creating cvtem for stock relationship 'is_plot_of' \n"; 
	
	my $plot_of = $schema->resultset("Cv::Cvterm")->create_with(
           { name   => 'is_plot_of',
	     cv     => 'stock relationship',
	     db     => 'null',
	     dbxref => 'is_plot_of',
	 });
	
	$parent_stock->find_or_create_related('stock_relationship_objects', {
	    type_id => $plot_of->cvterm_id(),
	    subject_id => $stock->stock_id(),
	} );
	

	$stock->create_stockprops( { year => $year }, { autocreate => 1 } );
	$stock->create_stockprops( { location => $location }, { autocreate => 1 } );
	$stock->create_stockprops( { replicate => $rep }, { autocreate => 1 } );
	
	
	########
	my @props = $stock->search_related('stockprops');
	foreach  my $p ( @props )  {
	    print "**the prop value for stock " . $stock->name() . " is   " . $p->value() . "\n"  if $p;
	}
	#########
    }
};



if ($@) {
    print "An error occured! Rolling backl!\n\n $@ \n\n "; 
    $dbh->rollback;
}
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    
    foreach my $value ( keys %seq ) { 
	my $maxval= $seq{$value} || 0;
	#print  "$key: $value, $maxval \n";
	if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    $dbh->rollback;
    
}else {
    print "Transaction succeeded! Commiting stocks, stockprops, and stock_relationships! \n\n";
    $dbh->commit();
}
