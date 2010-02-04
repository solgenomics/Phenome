
=head1

pop_locusgroups.pl

=head1 SYNOPSIS

    $pop_locusgroups.pl -H [dbhost] -D [dbname] [-t]

=head1 COMMAND-LINE OPTIONS

 -H  host name 
 -D  database name 
 -t  Test run . Rolling back at the end.


=head2 DESCRIPTION

This is a script for moving locus networks from phenome.locus2locus table to the locusgroup and locusgroup_member


=head2 AUTHOR

Naama Menda (nm249@cornell.edu)

July-2009
 
=cut


#!/usr/bin/perl
use strict;
use CXGN::DB::Connection;
use Getopt::Std; 
use CXGN::DB::InsertDBH;
use CXGN::Phenome::Locus2Locus;
use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusGroup;
use CXGN::Phenome::LocusgroupMember;
use CXGN::Phenome::Schema;

our ($opt_H, $opt_D, $opt_t);

getopts('H:tD:');

my $dbhost = $opt_H;
my $dbname = $opt_D;

my $dbh = CXGN::DB::InsertDBH->new( { dbhost=>$dbhost,
				      dbname=>$dbname,
                                      dbschema => 'phenome', 
				      dbargs => {AutoCommit => 0,
						 RaiseError => 1}
				  }
    );
my $schema= CXGN::Phenome::Schema->connect(  sub { $dbh->get_actual_dbh() },
					     { on_connect_do => ['SET search_path TO phenome, public;'],
					     },);

#$dbh->add_search_path(qw/public /);

#getting the last database ids for resetting at the end in case of rolling back
my $last_locusgroup_id= $schema->resultset('Locusgroup')->get_column('locusgroup_id')->max; 
my $last_lgm_id= $schema->resultset('LocusgroupMember')->get_column('locusgroup_member_id')->max; 

my $q= "SELECT locus2locus_id FROM phenome.locus2locus";
my $sth=$dbh->prepare($q);
$sth->execute();


eval {
#for each locus2locus record we need now to store 2 locusgroup members
    while (my ($l2l_id) = $sth->fetchrow_array()) { 
	
	my $l2l=CXGN::Phenome::Locus2Locus->new($dbh, $l2l_id);
	
	#2 new locusgroupMember objects. One for the locus object, one for the locus subject
	my $lg_object= CXGN::Phenome::LocusgroupMember->new($schema);
	my $lg_subject= CXGN::Phenome::LocusgroupMember->new($schema);
	
	$lg_object->set_locus_id($l2l->get_object_id());
	$lg_subject->set_locus_id($l2l->get_subject_id());
	print "The object id is ".  $l2l->get_object_id(). " The subject id is " . $l2l->get_subject_id() . "\n";
	my @accessors=(qw / sp_person_id obsolete create_date modified_date / );
	foreach my $a(@accessors) {
	    my $setter='set_'.$a;
	    my $getter= 'get_'.$a;
	    $lg_object->$setter($l2l->$getter );
	    $lg_subject->$setter($l2l->$getter );
	}
	
	my $rel_dbxref_id=$l2l->get_relationship_id();
	my $rel_dbxref= CXGN::Chado::Dbxref->new($dbh, $rel_dbxref_id);
	my $rel_cvterm=$rel_dbxref->get_cvterm();
	my $rel_name=$rel_cvterm->get_cvterm_name();
	
	#only the following relationships are directional
	if ( $rel_name eq 'Downstream' || $rel_name eq 'Upstream' || $rel_name eq 'Inhibition' || $rel_name eq 'Activation') {
	    $lg_object->set_direction('object');
	    $lg_subject->set_direction('subject');
	}
	#now see if the group exists for this relationship_id, and create one if needed
	my $group=$lg_object->find_or_create_group($rel_cvterm->get_cvterm_id(), $lg_subject );
	if (!$group) {
	    print "No group stores or found. Skipping to the next locus\n";
	    next();
	}
	$lg_object->set_locusgroup_id($group->get_locusgroup_id()) ;
	$lg_subject->set_locusgroup_id($group->get_locusgroup_id()) ;
	
	#evidence_id in locus2locus is a dbxref. We need to store a cvterm_id in locusgroup_member
	my $ev_dbxref_id=$l2l->get_evidence_id();
	my $ev_dbxref= CXGN::Chado::Dbxref->new($dbh, $ev_dbxref_id);
	my $ev_cvterm=$ev_dbxref->get_cvterm();
	$lg_object->set_evidence_id($ev_cvterm->get_cvterm_id()) ;
	$lg_subject->set_evidence_id($ev_cvterm->get_cvterm_id()) ;
	
	#Reference_id is a dbxref in both tables
	my $ref_dbxref_id=$l2l->get_reference_id();
	$lg_object->set_reference_id($ref_dbxref_id) ;
	$lg_subject->set_reference_id($ref_dbxref_id) ;
	
	#now store the 2 new members
	my $obj_id = $lg_object->store();
	my $subj_id = $lg_subject->store();
	print "Stored for group " . $group->get_locusgroup_name() . " object $obj_id and subject $subj_id\n";
	print "relationship = $rel_name, evidence= ". $ev_cvterm->get_cvterm_name() . "\n\n"; 
    }
};

if ($@) { print "An error occured! Rolling backl!\n\n $@ \n\n "; }
elsif ($opt_t) {
    print "TEST RUN. Rolling back and reseting database sequences!!\n\n";
    
    if ($last_locusgroup_id) { $dbh->do("SELECT setval ('phenome.locusgroup_locusgroup_id_seq', $last_locusgroup_id, true)"); }
    else { $dbh->do("SELECT setval ('phenome.locusgroup_locusgroup_id_seq', 1, false)"); }

    if ($last_lgm_id) { $dbh->do("SELECT setval ('phenome.locusgroup_member_locusgroup_member_id_seq', $last_lgm_id, true)"); }
    else { $dbh->do("SELECT setval ('phenome.locusgroup_member_locusgroup_member_id_seq', 1, false)"); }
    $dbh->rollback();

}else {
    print "Transaction succeeded! Commiting updates! \n\n";
    $dbh->commit();
}
