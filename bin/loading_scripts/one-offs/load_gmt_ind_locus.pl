################################################################################################################
#this script reads ;individual' accessions from a | delimited  file                                            # 
#and loads them into phenome.individual_locus (or not, if these accessions already exist),                     #
#Input is read from tomato_mutants_loci.txt ($ARGV[3]) in the following format:                                #
#
#+---------+-----------------+-----------------+----------------+
#| code    | allelic_to_tgrc | similar_to_tgrc | allelic_to_gmt |
#+---------+-----------------+-----------------+----------------+
#| e1444m1 | NULL            | an              | anantha        |
#| e1546m1 | NULL            | an              | anantha        |
#| e3430m1 | NULL            | an              | anantha        |
#                                                                                                              #   
##                                                                                                             #
################################################################################################################

#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
CXGN::DB::Connection->verbose(0);

unless($ARGV[0] eq 'scopolamine' or $ARGV[0] eq 'hyoscine'){die"First argument must be valid database host";}
unless($ARGV[1] eq 'sandbox' or $ARGV[1] eq 'cxgn'){die"Second argument must be valid database name";}
unless($ARGV[2] eq 'COMMIT' or $ARGV[2] eq 'ROLLBACK'){die'Third argument must be either COMMIT or ROLLBACK';}

unless ($ARGV[3]) {die 'you must provide a filename !';}

print "enter your password\n";

my $pass= <STDIN>;
chomp $pass;


my $phenome_dbh=CXGN::DB::Connection->new({dbname=> $ARGV[1], 
				   dbschema=>"phenome", 
				   dbhost=>$ARGV[0], 
				   dbuser=>"postgres", 
				   dbpass=>$pass,	
				   dbargs=>{AutoCommit=>0}});



my $phenome_sth = $phenome_dbh->prepare ("INSERT INTO phenome.individual_locus (locus_id, individual_id, sp_person_id, create_date)
                                          VALUES ((select locus_id from phenome.locus WHERE original_symbol ilike ?),
                                          (SELECT individual_id from phenome.individual WHERE name=? ), ?, now())");

my $individual_locus_sth = $phenome_dbh->prepare ("SELECT individual_locus_id FROM phenome.individual_locus WHERE 
                                               locus_id=(SELECT locus_id from phenome.locus WHERE original_symbol ilike ?) AND
                                               individual_id= (SELECT individual_id from phenome.individual WHERE name=? )");

eval {
    my $infile=open (my $infile, $ARGV[3]) || die "can't open file $ARGV[3]"; #./tomato_individual_loci.txt
   #my $sp_person= "Naama";
   #skip the first 5 lines
    <$infile>; <$infile>; <$infile>; <$infile>;
    <$infile>;
    while (my $line=<$infile>) {
	chomp $line;
	$line =~s/\s*//g;
	my @fields = split '\|', $line;
	print "$fields[1]";
	
	my $ind_name = $fields[1];
       
	my $existing_allele = $fields[2];
	my $tgrc_locus = $fields[3];
	my $gmt_allele= $fields[4];
	my $sp_person_id= 329; 
	
	
	if ($existing_allele eq "y") {
	    $individual_locus_sth->execute($tgrc_locus, $ind_name);
	    my ($individual_locus_id) = $individual_locus_sth->fetchrow_array();
	    unless ($individual_locus_id) {
		$phenome_sth->execute($tgrc_locus, $ind_name, $sp_person_id);
		$phenome_dbh->commit;
	    }
	}

    }
        
    warn "commiting loading data into phenome.individual_locus table";
    
};   


if ($@)  {
  warn "rolling back: $@\n";
  $phenome_dbh->rollback;
}else{ 
    print"Succeeded.\n";

}

