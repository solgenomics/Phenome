#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
use CXGN::Phenome::Individual;
use CXGN::Phenome::Population;
use CXGN::People::Person;
use CXGN::DB::InsertDBH;
use CXGN::Chado::CV;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Db;
use CXGN::Chado::Dbxref;

use CXGN::Phenome::Individual::IndividualDbxrefEvidence;

use Getopt::Std;

#CXGN::DB::Connection->verbose(0);

our ($opt_H, $opt_D, $opt_v,  $opt_t, $opt_i, $opt_u, $opt_p);

getopts('H:D:u:p:tvi:');

my $dbhost = $opt_H;
my $dbname = $opt_D;
my $infile = $opt_i;
my $sp_person_id=$opt_u; #280


if (!$infile) {
    print STDERR "\n You must provide an  infile!\n";
}
my $dbh;
if (!$dbhost && !$dbname) { 
    #print  STDERR "NO -D dbname and -H hostname arguments.\n"; 
    $dbh=CXGN::DB::Connection->new(); 
}else {
    $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				       dbname=>$dbname,
				       dbschema => 'phenome', 
				     } );
}
#my $person=CXGN::People::Person->new_with_name($dbh, $sp_person);
#xmy $sp_person_id=CXGN::People::Person->get_person_by_username($dbh, $sp_person); 


eval {
   my $infile=open (my $infile, $opt_i) || die "can't open file $infile!\n";   #./EUSOLacc1-1000.txt
 
   #skip the first line
   <$infile>;
   my $ind_id;
   my $ind;
   while (my $line=<$infile>) {
       my $common_name= 'Tomato';
       my $org_query= "SELECT common_name_id FROM sgn.common_name WHERE common_name ilike ?";
       my $org_sth=$dbh->prepare($org_query);
       $org_sth->execute($common_name);
       my ($common_name_id)=$org_sth->fetchrow_array();
       
       my @fields = split "\t", $line;
       my $eusol_id= $fields[0];
       my $name = $fields[2];

       my $lc_name= lc($name);
       my $full_name;
       my @split= split(/\s/, $lc_name);
       
       foreach (@split) {
	   $full_name .= " " if $full_name;
	   my $word = $_;
	   my $first=   substr( $_, 0, 1);
	   my $rest= substr $word, 1;
	   $full_name .= uc($first) . $rest;
       }
       
       my $sp= $fields[1];
       
       my $source= $fields[4] || undef;
       my $source_acc=$fields[3] || undef;
       my $description =undef;
       $description = "Source: $source" if $source;
       $description .= "\nID: $source_acc" if $source_acc;
       
       my $date= 0;
       if ($date ==0) {$date= 'now()'};
       $date=~ s/^(\d{8})(\d{6})/\1 \2-03/;
       chomp $date;
       print STDERR "$common_name (id = $common_name_id),  $full_name, $description\n";
       
       my $population_name; 
       
       $population_name = "Tomato Cultivars and Heirloom lines";
       
       my $population = CXGN::Phenome::Population->new_with_name($dbh, $population_name);
       
       my $db= CXGN::Chado::Db->new_with_name($dbh, 'EUSOL:accession');
       if (!$db->get_db_id) {
	   $db->set_db_name('EUSOL:accession');
	   $db->set_urlprefix('https://');
	   $db->set_url('www.eu-sol.wur.nl/dynamic/passport/searchAccessionsResults.php?accession=');
	   $db->set_description('EUSOL accessions for the Tomato Core Collection');
	   $db->store();
       }
       my @exists= CXGN::Phenome::Individual->new_with_name($dbh, $full_name, $population->get_population_id());
       
       my $eusol_dbxref;
       if (!@exists && $description) {
	   print STDERR "$full_name $description $date , $sp_person_id\n";
	   
	   $ind= CXGN::Phenome::Individual->new($dbh);
	   $ind->set_name($full_name);
	   $ind->set_description($description);
	   $ind->set_sp_person_id($sp_person_id);
	   $ind->set_population_id($population->get_population_id());
	   $ind->set_common_name_id($common_name_id);
	   $ind_id= $ind->store();
	  
       }else { 
	   print STDERR "individual name exists ($full_name) !\n Adding SP ontology anntation ...($sp)\n";
	   $ind=$exists[0];
       }
       
       $eusol_dbxref=CXGN::Chado::Dbxref->new($dbh); #do this only for the first row. Each accession has 1 EUSOL id
       $eusol_dbxref->set_db_name('EUSOL:accession');
       $eusol_dbxref->set_accession($eusol_id);
       $eusol_dbxref->store() ;
       
       $ind->add_individual_dbxref($eusol_dbxref, undef, $sp_person_id) if $eusol_dbxref;
       
       my (undef, $sp_acc) =  split ":" , $sp;
       my $sp_db_id= CXGN::Chado::Db->new_with_name($dbh, "SP")->get_db_id();
       my $sp_dbxref= CXGN::Chado::Dbxref->new_with_accession($dbh, $sp_acc, $sp_db_id);
       print STDERR "FOUND sp id: " . $sp_dbxref->get_accession() . " \n" ; 
       my $ind_dbxref_id= $ind->add_individual_dbxref($sp_dbxref, undef, $sp_person_id) ;
       my $evidence=CXGN::Phenome::Individual::IndividualDbxrefEvidence->new($dbh);
       $evidence->set_object_dbxref_id($ind_dbxref_id);
       $evidence->set_sp_person_id($sp_person_id);
       my $rel_cv=CXGN::Chado::CV->new_with_name($dbh, "relationship"); 
       my $rel=CXGN::Chado::Cvterm->new_with_term_name($dbh, 'has_phenotype', $rel_cv->get_cv_id()); 
       $evidence->set_relationship_type_id($rel->get_dbxref_id());
       my $ev_cv= CXGN::Chado::CV->new_with_name($dbh, 'evidence_code');
       my $ev= CXGN::Chado::Cvterm->new_with_term_name($dbh, 'inferred from direct assay', $ev_cv->get_cv_id() );
       $evidence->set_evidence_code_id($ev->get_dbxref_id);
       if (!$evidence->evidence_exists() ) { $evidence->store(); }
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



