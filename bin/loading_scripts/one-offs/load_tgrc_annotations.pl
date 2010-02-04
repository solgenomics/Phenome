#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
use CXGN::Phenome::Individual;

CXGN::DB::Connection->verbose(0);


unless($ARGV[0] eq 'scopolamine' or $ARGV[0] eq 'hyoscine'){die"First argument must be valid database host";}
unless($ARGV[1] eq 'sandbox' or $ARGV[1] eq 'cxgn'){die"Second argument must be valid database name";}
unless($ARGV[2] eq 'COMMIT' or $ARGV[2] eq 'ROLLBACK'){die'Third argument must be either COMMIT or ROLLBACK';}

print "enter your password\n";

my $pass= <STDIN>;
chomp $pass;

my $dbh=CXGN::DB::Connection->new({dbname=> $ARGV[1], 
				   dbschema=>"phenome", 
				   dbhost=>$ARGV[0], 
				   dbuser=>"postgres", 
				   dbpass=>$pass,	
				   dbargs=>{AutoCommit=>0}});
#mapping hash for tgrc categories and SP ontology terms
my %tgrc2sp = (
	       'A' => '0000016',
	       'B' => '0000017,0000052',
	       'C' => '0000017,0000053',
	       'D' => '0000017,0000055',
	       'E' => '0000017,0000054',
	       'F' => '0000017,0000026',
	       'G' => '0000057',
	       'H' => '0000151',
	       'I' => '0000018',
	       'J' => '0000004',
	       'K' => '0000002,0000003',
	       'L' => '0000008,0000009',
	       'M' => '0000007',
	       'N' => '0000014',
	       'O' => '0000011',
	       'P' => '0000012,0000013',
	       'Q' => '0000027',
	       'R' => '0000020',
	       'S' => '0000024',
	       'T' => '0000056',
	       'U' => '0000028',
	       'V' => '0000029',
	       'W' => '0000152',
	       'X' => '0000030',
	       'Y' => '0000035,0000036',
	       'Z' => '0000034',
	       );

my %name2id = (); #hash for retrieving existing individual ids and names 
#my %tgrc = ();  #retrieve individual-dbxref connections for tgrc individuals 
my %dbxref_hash = (); #retrieve dbxref_id - accession connections for solanaceae phenotype ontology 


my $individuals_query = "SELECT individual_id, name FROM phenome.individual";
my $sth = $dbh->prepare($individuals_query);
$sth->execute();
while (my ($id, $name) = $sth->fetchrow_array() ){ $name2id{lc($name)} = $id; }

my $individual_dbxref=  "SELECT individual_id, dbxref_id FROM phenome.individual_dbxref WHERE  individual_id =? AND dbxref_id=?";
my $sth2= $dbh->prepare($individual_dbxref);
#$sth2->execute();
#while (my ($ind, $dbxref) = $sth2->fetchrow_array() ) { $tgrc{$ind} = $dbxref;}

my $dbxref_query = "SELECT accession, dbxref_id FROM public.dbxref JOIN public.db using(db_id) WHERE public.db.name = 'SP'";
my $dbxref_sth=$dbh->prepare($dbxref_query);
$dbxref_sth->execute();
while (my ($accession, $id) = $dbxref_sth->fetchrow_array() ) { $dbxref_hash{$accession} = $id; }

eval {
    my $infile=open (my $infile, $ARGV[3]) || die "can't open file";   #./tgrc_annotations.txt
 
    #skip the first line
    <$infile>;
    while (my $line = <$infile>) {   
  	my @fields = split "\t", $line;
	my $individual_name = lc($fields[0]);
	
	my $tgrc_category = $fields[7];

	my $individual_id = $name2id{$individual_name};
	if ($individual_id) {
	    my $individual= CXGN::Phenome::Individual->new($dbh, $individual_id);
	    my $dbxref_acc = $tgrc2sp{$tgrc_category};
	    my @dbxref = split "," , $dbxref_acc ;
	    foreach my $accession (@dbxref)  {
		$sth2->execute($individual_id, $dbxref_hash{$accession});
		my ($individual_dbxref_id)= $sth2->fetchrow_array();
		if (!$individual_dbxref_id) {
		    $individual->associate_dbxref($dbxref_hash{$accession});
		    print "Inserting SP:$accession ($tgrc_category) - $individual_name into phenome.individual_dbxref \n";
		} else { print "**SP:$accession already associatef with individual $individual_id \n"; }
	    }
	}
    }
};   

if($@) {
    print $@;
    print"Failed; rolling back.\n";
    $dbh->rollback();
}else{ 
    print"Succeeded.\n";
    if($ARGV[2] eq 'COMMIT') {
        $dbh->commit();
    }else{
        $dbh->rollback();
    }
}
