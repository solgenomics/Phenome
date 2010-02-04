#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
use CXGN::Phenome::Individual;
use CXGN::Phenome::Population;
use CXGN::People::Person;
use CXGN::DB::InsertDBH;

use Getopt::Std;

CXGN::DB::Connection->verbose(0);

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
   my $infile=open (my $infile, $opt_i) || die "can't open file $infile!\n";   #./Pepper_mutants.txt
 
   #skip the first line
   <$infile>;
   
   while (my $line=<$infile>) {
       my $common_name= 'Pepper';
       my $org_query= "SELECT common_name_id FROM sgn.common_name WHERE common_name ilike ?";
       my $org_sth=$dbh->prepare($org_query);
       $org_sth->execute($common_name);
       my ($common_name_id)=$org_sth->fetchrow_array();
       
       my @fields = split "\t", $line;
       my $name = $fields[0];
       my $description= $fields[1];
       my $date= 0;
       if ($date ==0) {$date= 'now()'};
       $date=~ s/^(\d{8})(\d{6})/\1 \2-03/;
       chomp $date;
       print STDERR "$common_name (id = $common_name_id),  $name, $description\n";
       
       my $population_name; 
       
       if ($name =~ m/^pe/) {
	   $population_name = "Pepper EMS mutant population";
       }else { next(); }
       my $population = CXGN::Phenome::Population->new_with_name($dbh, $population_name);
       
       #$check_sth->execute($name);
       #my ($individual_id) = $check_sth->fetchrow_array();
       my $ind= CXGN::Phenome::Individual->new($dbh);
       my @exists= CXGN::Phenome::Individual->new_with_name($dbh, $name);
       $ind->set_name($name);
       $ind->set_description($description);
       $ind->set_sp_person_id($sp_person_id);
       $ind->set_population_id($population->get_population_id());
       $ind->set_common_name_id($common_name_id);
       if (!@exists && $description) {
	   print STDERR "$name $description $date , $sp_person_id\n";
	   $ind->store();
	   #$sth->execute($name, $description, $first_name, $last_name, $date, $population);
       }else { print STDERR "individual name exists (@exists) !\n "; }
       
   }
};   

if($@) {
    print $@;
    print"Failed; rolling back.\n";
    $dbh->rollback();
}else{ 
    print"Succeeded.\n";
    if (!$opt_t) {
	print STDERR "committing ! \n";
        $dbh->commit();
    }else{
	print STDERR "Rolling back! \n";
        $dbh->rollback();
    }
}



