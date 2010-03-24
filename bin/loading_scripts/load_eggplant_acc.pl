#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
use CXGN::Phenome::Individual;
use CXGN::Phenome::Population;
use CXGN::People::Person;
use CXGN::DB::InsertDBH;

use Getopt::Std;


our ($opt_H, $opt_D, $opt_v,  $opt_t, $opt_i, $opt_u, $opt_p);

getopts('H:D:u:p:tvi:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $infile = $opt_i;
my $sp_person=$opt_u;
#my $sp_person_id = $opt_p || "329";

if (!$infile) {
    print STDERR "\n You must provide an  infile!\n";
}

if (!$dbhost && !$dbname) { 
    print  STDERR "Need -D dbname and -H hostname arguments.\n"; 
}

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
                                      dbschema => 'phenome', 
                                   } );

#my $person=CXGN::People::Person->new_with_name($dbh, $sp_person);
my $sp_person_id=CXGN::People::Person->get_person_by_username($dbh, $sp_person);


eval {
   my $infile=open (my $infile, $opt_i) || die "can't open file $infile!\n";   #./epplant.txt
 
   #skip the first line
   <$infile>;
   
   while (my $line=<$infile>) {
       my $common_name= 'Eggplant';
       my $org_query= "SELECT common_name_id FROM sgn.common_name WHERE common_name ilike ?";
       my $org_sth=$dbh->prepare($org_query);
       $org_sth->execute($common_name);
       my ($common_name_id)=$org_sth->fetchrow_array();
       
       my @fields = split "\t", $line;
       my $cname= $fields[0];
       my $accession = $fields[1];
       my $organism= $fields[2];
       my $origin = $fields[3];
       my $comments = $fields[4];
       my $source= $fields[5];
       my $photo_acc = $fields[6];
       chomp $photo_acc;
       
       my $description = "";
       $description .= "Common name: $cname\n" if $cname;
       $description .= "Organism: $organism\n" if $organism;
       $description .= "Origin: $origin\n" if $origin;
       $description .= "Source database: $source\n" if $source;
       $description .= $comments;
       
       my $date= 0;
       if ($date ==0) {$date= 'now()'};
       $date=~ s/^(\d{8})(\d{6})/\1 \2-03/;
       chomp $date;
       #print STDOUT "$common_name (id = $common_name_id),  $cname, $accession\n";
       
              
       my $population_name = "Eggplant accessions";
       my $population = CXGN::Phenome::Population->new_with_name($dbh, $population_name);
       if (!$population) {
	   $population = CXGN::Phenome::Population->new($dbh);
	   $population->set_name($population_name);
	   $population->set_description("Eggplant accessions.... ");
	   $population->set_common_name_id($common_name_id);
	   $population->set_sp_person_id($sp_person_id);
	   $population->store();
       }
       
       my $ind= CXGN::Phenome::Individual->new($dbh);
       my @exists= CXGN::Phenome::Individual->new_with_name($dbh, $accession);
       $ind->set_name($accession);
       $ind->set_description($description);
       $ind->set_sp_person_id($sp_person_id);
       $ind->set_population_id($population->get_population_id());
       $ind->set_common_name_id($common_name_id);
       if (!@exists && $description) {
	   print STDOUT "$accession  $description \n";
	   $ind->store();
	   $ind->add_individual_alias($photo_acc, $sp_person_id) if $photo_acc;
	 	   
       }else { print STDOUT "individual name exists ($exists[0] , $accession) !\n "; }
       
   }
};   

if($@) {
    print $@;
    print"Failed; rolling back.\n";
    $dbh->rollback();
}else{ 
    print"Succeeded.\n";
    if (!$opt_t) {
	print STDOUT "committing ! \n";
        $dbh->commit();
    }else{
	print STDOUT "Rolling back! \n";
        $dbh->rollback();
    }
}



