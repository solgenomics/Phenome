
=head1

load_lycotill_stocks.pl

=head1 SYNOPSIS

    $this_script.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name
 -D  database name
 -i infile
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION



Naama Menda (nm249@cornell.edu)

    March 2011

=cut


#!/usr/bin/perl
use strict;
use Getopt::Std;
use File::Slurp;

use Bio::Chado::Schema;
use CXGN::DB::InsertDBH;
use Carp qw /croak/ ;

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

my $prefix = 'LycoTILL';

# load a new LycoTILL population
# load stocks
# load SP annotations in stock_cvterm
#load images in metadata.md_image, then link the image as a stockprop type_id = 'sgn image_id ' value = $image_id


#getting the last database ids for resetting at the end in case of rolling back
my $last_stockprop_id= $schema->resultset('Stock::Stockprop')->get_column('stockprop_id')->max;
my $last_stock_id= $schema->resultset('Stock::Stock')->get_column('stock_id')->max;
my $last_stockrel_id= $schema->resultset('Stock::StockRelationship')->get_column('stock_relationship_id')->max;
my $last_cvterm_id= $schema->resultset('Cv::Cvterm')->get_column('cvterm_id')->max;
my $last_cv_id= $schema->resultset('Cv::Cv')->get_column('cv_id')->max;
my $last_db_id= $schema->resultset('General::Db')->get_column('db_id')->max;
my $last_dbxref_id= $schema->resultset('General::Dbxref')->get_column('dbxref_id')->max;
my $last_organism_id = $schema->resultset('Organism::Organism')->get_column('organism_id')->max;
my $last_stock_cvterm_id = $schema->resultset('Stock::StockCvterm')->get_column('stock_cvterm_id')->max;

my %seq  = (
    'db_db_id_seq'                    => $last_db_id,
    'dbxref_dbxref_id_seq'            => $last_dbxref_id,
    'cv_cv_id_seq'                    => $last_cv_id,
    'cvterm_cvterm_id_seq'            => $last_cvterm_id,
    'stock_stock_id_seq'              => $last_stock_id,
    'stockprop_stockprop_id_seq'      => $last_stockprop_id,
    'stock_cvterm_stock_cvterm_id_seq'=> $last_stock_cvterm_id,
    'organism_organism_id_seq'        => $last_organism_id,
    'stock_relationship_stock_relationship_id_seq' => $last_stockrel_id,
    );


my @lines = read_file($file);

my $population_name = 'LycoTILL tomato cultivar Red Setter EMS mutant population';
my $species = 'Solanum lycopersicum';

#Olimpia D'onofrio
# processing tomato cultivar red setter 
my $pmid = '20222995';
my $pub = $schema->resultset('General::Db')->search( { name => 'PMID' })->
    search_related('dbxrefs', { accession => $pmid } )->
    search_related('pub_dbxrefs')->
    search_related('pub')->first;

if (!$pub) { die "Need to preload pubmed id $pmid in the databse before running this loader! \n" ; }
my $sp_person_id = CXGN::People::Person->get_person_by_username($dbh, 'LycoTILL');
die "Need to have LycoTILL user pre-loaded in the sgn database! " if !$sp_person_id;


my $organism = $schema->resultset("Organism::Organism")->find_or_create( {
    species => $species } );
my $organism_id = $organism->organism_id();

## For the stock module:

#the cvterm for the population
print "Finding/creating cvterm for mutant population\n";
my $population_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
    { name   => 'mutant population',
      cv     => 'stock type',
      db     => 'null',
      dbxref => 'autocreated:mutant population',
    });

my $url_prefix = 'http://';
my $accession_url = 'www.agrobios.it/tilling/plantPhenotype.php?plantcode=';
my $lyco_url = 'www.agrobios.it/tilling/';
# create the db names for LycoTILL

my $lycotill_db = $schema->resultset("General::Db")->find_or_create(
    {
        name      => 'LycoTILL',
        urlprefix => $url_prefix,
        url       => $lyco_url,
    } );
my $lycotill_dbxref = $lycotill_db->find_or_create_related('dbxrefs', { accession => 'LycoTILL' });

my $lycotill_accession_db = $schema->resultset("General::Db")->find_or_create(
    {
        name      => 'LycoTILL accession',
        urlprefix => $url_prefix,
        url       => $accession_url,
    } );

################################
print "creating new stock for population $population_name\n";
my $stock_population = $schema->resultset("Stock::Stock")->find_or_create(
    { organism_id => $organism_id,
      name  => $population_name,
      uniquename => $population_name,
      type_id => $population_cvterm->cvterm_id(),
    } );
$stock_population->find_or_create_related('stock_dbxrefs' , { dbxref_id => $lycotill_dbxref->dbxref_id, } );
$stock_population->find_or_create_related('stock_pubs' , { pub_id => $pub->pub_id } );


print "parsing data file ... \n";
my $stock_count;
print "Loading .... \n" ;
eval {
    foreach my $line (@lines ) {
        chomp $line;
	my ($accession, undef, undef, $sp_term) = split /\t/ , $line ;
        my ($sp_db_name, $sp_accession) = split ':' , $sp_term;
	#the cvterm for the accession
        my $accession_cvterm = $schema->resultset("Cv::Cvterm")->create_with(
	    { name   => 'accession',
	      cv     => 'stock type',
	      db     => 'null',
	      dbxref => 'accession',
	    });
	my $stock = $schema->resultset("Stock::Stock")->find_or_create(
	    { organism_id => $organism_id,
	      name  => $prefix . ":" . $accession,
	      uniquename => $prefix . ":" . $accession,
	      type_id => $accession_cvterm->cvterm_id()
	    });
        #store a dbxref for the lycotill accession. This will be used to construct
        #the reciprocal link to the lycoTILL web site
        my $accession_dbxref = $lycotill_accession_db->find_or_create_related('dbxrefs', { accession => $accession });
        $stock->find_or_create_related('stock_dbxrefs', { dbxref_id => $accession_dbxref->dbxref_id } );
        $stock_count++;
	#add the owner for this stock
	$stock->create_stockprops( { sp_person_id => $sp_person_id }, { autocreate => 1, cv_name => 'local' } );
        #the stock belongs to the population:
        #add new stock_relationship
	#the cvterm for the relationship type
        my $member_of = $schema->resultset("Cv::Cvterm")->create_with(
           { name   => 'member_of',
	     cv     => 'stock relationship',
	     db     => 'null',
	     dbxref => 'member_of',
	 });

	$stock_population->find_or_create_related('stock_relationship_objects', {
	    type_id => $member_of->cvterm_id(),
	    subject_id => $stock->stock_id(),
                                                  } );
        # add the publication
        $stock->find_or_create_related('stock_pubs' , { pub_id => $pub->pub_id } );

        #now load the ontology annotation
        my $sp_cvterm = $schema->resultset('General::Db')->search(
            { 'me.name' => $sp_db_name } )->
            search_related('dbxrefs' , { accession => $sp_accession } )->
            search_related('cvterm')->first;
        $stock->find_or_create_related('stock_cvterms' , {
            cvterm_id => $sp_cvterm->cvterm_id,
            pub_id   => $pub->pub_id,
                                       } );
    }
};


print "Created $stock_count new stocks \n\n";
if ($@) {
    print "An error occured! Rolling backl!\n\n $@ \n\n "; 
    $dbh->rollback();
}
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";  
    foreach my $value ( keys %seq ) { 
	my $maxval= $seq{$value} || 0;
	#print  "$key: $value, $maxval \n";
	if ($maxval) { $dbh->do("SELECT setval ('$value', $maxval, true)") ;  }
	else {  $dbh->do("SELECT setval ('$value', 1, false)");  }
    }
    $dbh->rollback();

}else {
    print "Transaction succeeded! Commiting cvtermprops! \n\n";
    $dbh->commit();
}
