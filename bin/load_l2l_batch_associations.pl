use strict;
use warnings;


#use CXGN::DB::Connection;
#use CXGN::Login;
#use CXGN::Contact;
#use CXGN::People::Person;
use CXGN::Phenome::Locus2Locus;
use CXGN::Phenome::Locus;
use CXGN::DB::InsertDBH;

use Getopt::Std;

our ($opt_H, $opt_D, $opt_x);

getopts('H:D:x');

print STDERR "opt_H = $opt_H\n";

######data that need to be provided #####################3
my $locus_name = 'locus name with put the suffix number'; #locus name with out the suffix number
my $locus_symbol = 'locus symbol'; #locus symbol without the number suffix
my $organism = 'tomato'; #well, you know what..:
#my $subject_id = 5584;

my $relationship_type= 'homolog'; # eg. 'homolog'
my $evidence_type = 'sequence or structural similarity'; # eg. 'sequence or structural similarity'
my $pubmed_id = 12514239;
my $sp_person_id = 865;

#################################

my ($evidence_id,  $reference_id, $relationship_id);
my $count=0;

$locus_name =~ /(\w+)/;
$locus_name =$1;
print "$locus_name\n";
$locus_symbol =~ /(\D+)/;
$locus_symbol =$1;

print "$locus_symbol\n";


my $dbh = CXGN::DB::InsertDBH->new({dbname=>$opt_D, dbhost=>$opt_H, dbuser=>"postgres"});
my (@all_locus_id, @all_symbol, @all_name, @all_organism);


###### retreiving relationship id, evidence_id, and reference_id (dbxrefs)
my $sth_rel = $dbh->prepare("SELECT cvterm.dbxref_id FROM public.cvterm 
                                    WHERE cvterm.name ILIKE ? 
                                    AND cvterm.is_obsolete = 0");

$sth_rel->execute($relationship_type);
($relationship_id) = $sth_rel->fetchrow_array();

my $sth_evi = $dbh->prepare("SELECT dbxref_id FROM public.cvterm where cv_id = 19 AND cvterm.name ILIKE '%$evidence_type'");
$sth_evi->execute();
($reference_id) = $sth_evi->fetchrow_array();

my $sth_ref = $dbh->prepare("SELECT dbxref_id FROM public.dbxref WHERE accession = ?");
$sth_ref->execute($pubmed_id);
($reference_id) = $sth_ref->fetchrow_array();

###############################################


if (($locus_name) && ($organism)) {
    my $locus_query = "SELECT locus_id, locus_symbol, locus_name, common_name FROM phenome.locus 
                                   JOIN sgn.common_name USING (common_name_id) 
                                   WHERE locus_symbol ILIKE '$locus_symbol%' AND locus_name ILIKE '$locus_name%'
                                   AND common_name ILIKE '$organism' AND locus.obsolete='f'"; 
  

#AND (locus_id != $object_id)
    my $sth = $dbh->prepare($locus_query);
    $sth->execute();
	    
    while ( my ($all_locus_id, $all_symbol, $all_name, $all_organism) = $sth->fetchrow_array()) {

	push @all_locus_id, $all_locus_id;
	push @all_symbol, $all_symbol;
	push @all_name, $all_name;
	push @all_organism, $all_organism;
	
	print "retreiving locus_id: $all_locus_id\t symbol: $all_symbol\t name: $all_name\t organism: $all_organism\n";
    }
}


for (my $i=0; $i<@all_name; $i++) {
    my $subj_id = $all_locus_id[$i];
    my $subj_name = $all_name[$i];
    my $subj_symbol = $all_symbol[$i];
    my $subj_name_full = $subj_name;
    
    $subj_name =~ /(\w+)/;
    $subj_name =$1;

    $subj_symbol =~/(\D+)/;
    $subj_symbol =$1;

    my $locus_query = "SELECT locus_id, locus_symbol, locus_name, common_name FROM phenome.locus 
                             LEFT JOIN sgn.common_name USING (common_name_id)
                             WHERE (locus_name ILIKE '$subj_name%' 
                             AND locus_symbol ILIKE '$subj_symbol%'
                             AND locus_name NOT ILIKE '$subj_name_full') 
                             AND (sgn.common_name.common_name ILIKE '$organism') 
                             AND locus.obsolete='f'"; 
	
	#if (!$reference_id) {$reference_id = undef};
	
    my $sth = $dbh->prepare($locus_query);
    $sth->execute();
    my (@obj_id, @symbol, @name, @common_name);
    my ($obj_id, $symbol, $name, $common_name);



    while (($obj_id, $symbol, $name, $common_name) = $sth->fetchrow_array()) {
	my $sth1 = $dbh->prepare("SELECT locus2locus_id FROM phenome.locus2locus 
                                  WHERE (subject_id = $subj_id AND object_id  = $obj_id) 
                                  OR (subject_id = $obj_id AND object_id  = $subj_id) ");
	$sth1->execute();
	my ($l2l_id1) = $sth1->fetchrow_array();
	
	print "l2l_id1: $l2l_id1\n";
	if ($l2l_id1)  {print "l2l association already exists for locus: $subj_id\n";} 
	else {
		my $locus2locus=CXGN::Phenome::Locus2Locus->new($dbh);
		$locus2locus->set_subject_id($subj_id);
		$locus2locus->set_object_id($obj_id);
		$locus2locus->set_relationship_id($relationship_id);
		$locus2locus->set_evidence_id($evidence_id);
		$locus2locus->set_reference_id($reference_id);
		$locus2locus->set_sp_person_id($sp_person_id);
	
		print STDERR "Storing...object: $obj_id to subject: $subj_id\n";
	
		my $locus2locus_id=$locus2locus->store();
		$count++;

		if ($@) { warn "Locus to locus  association failed! $@"; }  
	    
#	}#else {print "l2l association already exists for locus: $subj_id\n";}
#    }
#}


#	    my $person = CXGN::People::Person->new($sp_person_id);
	
	    
#	    my $user_link = qq |http://www.sgn.cornell.edu/solpeople/personal-info.pl?sp_person_id=$sp_person_id |;
#	    my $subject_locus_link= qq |http://www.sgn.cornell.edu/phenome/locus_display.pl?locus_id=$subj_id |;
#	    my $object_locus_link= qq |http://www.sgn.cornell.edu/phenome/locus_display.pl?locus_id=$obj_id |;
#	    my $subject="[New locus2locus association created]";
#	    my $username= $person->get_first_name()." ".$person->get_last_name();
#	    my $fdbk_body="$username ($user_link) has associated locus $object_locus_link \n to locus $subject_locus_link \n "; 
	   
#	    CXGN::Contact::send_email($subject,$fdbk_body, 'iyt2@cornell.edu');
	}
	
    }
}

print "$count associations created\n";
if ($@ || $opt_x) { 
   $dbh->rollback();
  print STDERR "An error occurred: $@\n";
    
}
else { 
  print STDERR "Committing...\n";
   $dbh->commit();
}

#$dbh->rollback();
#print STDERR "Done.  \n";
#}
