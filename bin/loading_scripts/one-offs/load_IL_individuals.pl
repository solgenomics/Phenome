#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;

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

my $check_i_sth = $dbh->prepare("SELECT individual_id from individual where name = ?");
my $check_l_sth= $dbh->prepare("SELECT individual_locus_id from individual_locus where locus_id= (SELECT locus_id from locus where original_symbol ilike  ?) AND individual_id= (SELECT individual_id from individual where name = ?)");
my $check_a_sth = $dbh->prepare("SELECT individual_allele_id from individual_allele where allele_id = (SELECT allele_id from allele where allele_symbol ilike ? AND locus_id = (SELECT locus_id from locus where original_symbol ilike  ?)) AND individual_id= (SELECT individual_id from individual where name = ?)");

my $individual_sth= $dbh->prepare ("INSERT INTO individual (name, sp_person_id,  population_id) values (?,  (select sp_person_id from sgn_people.sp_person where first_name = 'Dani' and last_name = 'Zamir'), (select population_id from population where name ilike ?))");

my $locus_sth= $dbh->prepare("INSERT INTO individual_locus (individual_id, locus_id, sp_person_id) VALUES (?, (SELECT locus_id from locus where original_symbol ilike ?), (SELECT sp_person_id from individual where individual_id = ?))");

my $allele_sth= $dbh->prepare("INSERT INTO individual_allele (individual_id, allele_id, sp_person_id) VALUES (?, (SELECT allele_id from allele where allele_symbol ilike ? AND locus_id= (SELECT locus_id from locus where original_symbol ilike ?)), (SELECT sp_person_id from individual where individual_id = ?))");


eval {
    my $infile=open (my $infile, $ARGV[3]) || die "can't open file";   #./IL_list.txt
    

    my $individual_count=0;
    my  $locus_count =0;
    my  $allele_count=0;
    while (my $line=<$infile>) {
#	$line = ~s/\s//g;
	my @fields = split "\t", $line;
	my $name = $fields[1];
	
	my $population = "M82 x S.pennellii IL population"; 
	
#	print "@fields\n";
	my $locus_symbol;
	my $allele_symbol;
	
	if ($name =~/^IL/) {
	    $check_i_sth->execute($name);
	    my ($individual_id) = $check_i_sth->fetchrow_array();
	    if (!$individual_id) {
		$individual_sth->execute($name, $population);
		$individual_count++; ##
		$individual_id= $dbh->last_insert_id("individual", "phenome");
	
		if ($locus_symbol) { 
		    $locus_sth->execute($individual_id, $locus_symbol, $individual_id) ;
		    print "inserting into individual and individual_locus: $individual_id\t $name\ $locus_symbol\n"; 
		    $locus_count++; #
		}
		if ($allele_symbol) {
		    $check_a_sth->execute($allele_symbol, $locus_symbol, $name);
		    my ($allele_id) = $check_a_sth->fetchrow_array();
 		    if (!$allele_id) {
			$allele_sth->execute($individual_id, $allele_symbol, $locus_symbol, $individual_id);
			print "inserting into individual_allele: $individual_id\t $name\ $allele_symbol\n"; 
			$allele_count++; #
		    }
		}
	   # }else {
 	#	$check_l_sth->execute($locus_symbol, $name);
 	#	my ($locus_id) = $check_l_sth->fetchrow_array();
 	#	if (!$locus_id) {
	#	    print "$name $allele_symbol $locus_symbol $population\n";
 	#	    $locus_sth->execute($individual_id, $locus_symbol, $individual_id);
	#	    print "inserting into individual_locus: $individual_id\t $name\ $locus_symbol\n"; 
 	#	    $locus_count++; #
 	#	    if ($allele_symbol) {
	#		$check_a_sth->execute($allele_symbol, $locus_symbol, $name);
	#		my ($allele_id) = $check_a_sth->fetchrow_array();
	#		if (!$allele_id) {
	#		    $allele_sth->execute($individual_id, $allele_symbol, $locus_symbol, $individual_id);
	#		    print "inserting into individual_allele: $individual_id\t $name\ $allele_symbol\n"; 
	#		    $allele_count++; #
	#		}
	#	    }
	#	}
	
	    }
	    
	    my $ILh = "ILH". substr $name, 2;
	    print "$ILh\n";
	    
	    $check_i_sth->execute($ILh);
	    my ($individual_id) = $check_i_sth->fetchrow_array();
	    if (!$individual_id) {
		$individual_sth->execute($ILh, $population);
		$individual_count++; ##
	    }
#		else {
# 		    $check_a_sth->execute($allele_symbol, $locus_id);
# 		    my ($allele_id) = $check_a_sth->fetchrow_array();
# 		    if (!$allele_id) {
# 			if ($allele_symbol) {
# 			    $allele_sth->execute($individual_id, $allele_symbol, $locus_symbol, $individual_id);
# 			    $allele_count++;
# 			}
# 		    }
# 		}
#	     }
	}
    }
   print "inserted $individual_count individuals\t $locus_count individual_locus\t $allele_count individual_allele\n";
   
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



