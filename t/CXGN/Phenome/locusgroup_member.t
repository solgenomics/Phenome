#!/usr/bin/perl

=head1 NAME

  locusgroup_member.t
  A test for  CXGN::Phenome::LocusgroupMember class

=cut

=head1 SYNOPSIS

 perl locusgroup_member.t



=head1 DESCRIPTION

Testing creating gene networks using locusgroup and  locusgroup_member tables.
Both tables have DBIx::Class objects.

When creating a gene network we need 2 loci, a relationship type, and a direction if relevant 
(e.g. orthologs are non-directional, but 'downstream', 'inhibition' and 'activation' are, in such case we have to determine 
which locus is the subject and which is the object).

Then before storing both loci in locusgroup_member we need to find if:

-the relationship is directional. Then only 2 members can exist in the group.
 Need to check first if 
    -the loci are already associated or 
    -if the new association creates a conflict 
 in both cases nothing will be stored 

###############

If the relationship is non-directional, check if:

-The loci are already associated

-The user attemps to link the locus to itself

-One common group already exists for any of these loci with the given relationship type 
    then  the non-existing locus will be added to the group of the other locus

-The new link creates a new connection between 2 existing groups.
    The 2 groups will be merged, all members will get the id of teh first group, and the latter group will be obsolete.

-No group exists for any of the loci with this relationship type
    then a new group will be created and both loci added to the group.


=head2 Author

Naama Menda <n249@cornell.edu>

    
=cut

use strict;

use Test::More tests=>35; #qw / no_plan / ; 
use CXGN::DB::Connection;
use CXGN::Phenome::Locus;
use CXGN::Phenome::LocusgroupMember;
use CXGN::Phenome::LocusGroup;
use CXGN::Chado::CV;
use CXGN::Chado::Cvterm;

use Data::Dumper;

BEGIN {
    use_ok('CXGN::Phenome::Schema');
    use_ok('CXGN::Phenome::LocusgroupMember');
}

#if we cannot load the CXGN::Phenome::Schema module, no point in continuing
CXGN::Phenome::Schema->can('connect')
    or BAIL_OUT('could not load the CXGN::Phenome::Schema  module');

my $dbh=CXGN::DB::Connection->new();
$dbh->add_search_path(qw/ phenome public / );
my $schema=  CXGN::Phenome::Schema->connect(  sub { $dbh->get_actual_dbh() } );



my $last_lgm_id= $schema->resultset('LocusgroupMember')->get_column('locusgroup_member_id')->max; 
my $last_lg_id= $schema->resultset('Locusgroup')->get_column('locusgroup_id')->max; 


# make a new locusgroup_member and store it, all in a transaction. 
# then rollback to leave db content intact.

eval {
    #my $row=$schema->resultset('Organism::Organism')->create();
   
    #1. Store a directional group
    diag("Directional group test! \n");
    my $lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    my $associated_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    
    #store new loci for the testing:
   
    my $locus_id = 1; #the subject
    my $associated_locus_id= 2; #the object
    my $relationship='Downstream' ;#locus 2 is downstream of locus 1
    my $evidence= 'inferred from direct assay';
    my $d1='object';
    my $d2='subject';


##########
    my $rel_cv=CXGN::Chado::CV->new_with_name($dbh, 'Locus Relationship');
    my $rel_cvterm=CXGN::Chado::Cvterm->new_with_term_name($dbh, $relationship, $rel_cv->get_cv_id());
    my $relationship_id= $rel_cvterm->get_cvterm_id();
    
    my $ev_cv= CXGN::Chado::CV->new_with_name($dbh, 'evidence_code');
    my $ev_cvterm=CXGN::Chado::Cvterm->new_with_term_name($dbh, $evidence, $ev_cv->get_cv_id());
    my $ev_id= $ev_cvterm->get_cvterm_id();
    
    ##########
    
    $lgm->set_locus_id($locus_id);
    $lgm->set_evidence_id($ev_id);
    $lgm->set_direction($d1);

    $associated_lgm->set_locus_id($associated_locus_id);
    $associated_lgm->set_evidence_id($ev_id);
    $associated_lgm->set_direction($d2);
    
    my $locusgroup= $lgm->find_or_create_group($relationship_id, $associated_lgm);
  
    my $lg_id= $locusgroup->get_locusgroup_id();
    $lgm->set_locusgroup_id($lg_id);
    $associated_lgm->set_locusgroup_id($lg_id);
    
    my $lgm_id= $lgm->store();
    my $algm_id=$associated_lgm->store();
       
    my $re_lgm= CXGN::Phenome::LocusgroupMember->new($schema, $lgm_id);
    is($re_lgm->get_locus_id(), $locus_id, "Locus id test");
    is($re_lgm->get_locusgroup_id(), $locusgroup->get_locusgroup_id(), "Locusgroup id test");
    is($re_lgm->get_evidence_id(), $ev_id, "evidence id test");
    is($re_lgm->get_direction(), $d1, "Direction test");
    is($re_lgm->get_locusgroup()->get_relationship_id(), $relationship_id, "Relationship id test");

##########################################
    #2. Now try to store the same thing
    diag("Store existing network test\n");
    $lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    $associated_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    
    ##########
    
    $lgm->set_locus_id($locus_id);
    $lgm->set_evidence_id($ev_id);
    $lgm->set_direction($d1);

    $associated_lgm->set_locus_id($associated_locus_id);
    $associated_lgm->set_evidence_id($ev_id);
    $associated_lgm->set_direction($d2);
    
    $locusgroup= $lgm->find_or_create_group($relationship_id, $associated_lgm);
   
    $lg_id= $locusgroup->get_locusgroup_id();
    $lgm->set_locusgroup_id($lg_id);
    $associated_lgm->set_locusgroup_id($lg_id);
    
    my $stored_lgm_id= $lgm->store();            # this should store nothing since the locus is already a group member
    my $stored_algm_id=$associated_lgm->store(); # this should store nothing since the locus is already a group member
       
    is($stored_lgm_id, $lgm_id, "Locus member exists  test");
    is($stored_algm_id, $algm_id, "Associated locus member exists  test");

    $re_lgm= CXGN::Phenome::LocusgroupMember->new($schema, $stored_lgm_id);
    is($re_lgm->get_locus_id(), $locus_id, "Locus id test");
    is($re_lgm->get_locusgroup_id(), $locusgroup->get_locusgroup_id(), "Locusgroup id test");
    is($re_lgm->get_evidence_id(), $ev_id, "evidence id test");
    is($re_lgm->get_direction(), $d1, "Direction test");
    is($re_lgm->get_locusgroup()->get_relationship_id(), $relationship_id, "Relationship id test");
    
#######################
    #3. Store another locus downstream. A new group should be created since only 2 members can live in 1 directional group! 

    ############################
#######################
################
##############

    diag("Create 2nd directional group test! \n");
    $lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    $associated_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    
    #store new loci for the testing:
   
    # $locus_id = 1; #the subject
    my $new_locus_id= 3; #the object - a 2nd locus downstream of locus1
   
    ##########
    
    $lgm->set_locus_id($locus_id);
    $lgm->set_evidence_id($ev_id);
    $lgm->set_direction($d1);

    $associated_lgm->set_locus_id($new_locus_id);
    $associated_lgm->set_evidence_id($ev_id);
    $associated_lgm->set_direction($d2);
    
    my $new_locusgroup= $lgm->find_or_create_group($relationship_id, $associated_lgm); # create a new directional locus group
  
    my $new_lg_id= $new_locusgroup->get_locusgroup_id();
    $lgm->set_locusgroup_id($new_lg_id);
    $associated_lgm->set_locusgroup_id($new_lg_id);
    
    # check that the locusgroup is new
    isnt($new_lg_id, $lg_id, "New directional locus group id test");
    
    $lgm_id= $lgm->store();
    $algm_id=$associated_lgm->store();
    
    #check that both directional locus groups have only 2 members
    my @members= $locusgroup->get_locusgroup_members();
    my @member_ids = map($_->get_column('locus_id'), @members);
    is(scalar(@members), 2, "Locus group 2 members test");
    my @expected= ($locus_id,$associated_locus_id);
    ok( eq_set(\@member_ids, \@expected) );

    my @new_members=$new_locusgroup->get_locusgroup_members();
    my @new_ids = map ($_->get_column('locus_id'), @new_members);
    
    is(scalar(@new_members), 2, "New locus group 2 members test");
    my @new_expected=($locus_id,$new_locus_id);
    
    ok( eq_set(\@new_ids, \@new_expected) );
    
    
###################################
################
############
    #4. Associate a locus to itself..
    
    diag("Store self test\n");
    $lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    $associated_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    
    ##########
    
    $lgm->set_locus_id($locus_id);
    $lgm->set_evidence_id($ev_id);
    $lgm->set_direction($d1);

    $associated_lgm->set_locus_id($locus_id);
    $associated_lgm->set_evidence_id($ev_id);
    $associated_lgm->set_direction($d2);
    
    $locusgroup= $lgm->find_or_create_group($relationship_id, $associated_lgm); # this should return undef! 
    
    is($locusgroup, undef, "Associate to self test");
    
##############
    #5 Try to store a conflict
    diag("Store conflict test\n");
    eval { # this is in a nested eval. LocusgroupMember->find_or_create_group should return undef!
	$lgm = CXGN::Phenome::LocusgroupMember->new($schema);
	$associated_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
	
	##########
        
	$lgm->set_locus_id($associated_locus_id);
	$lgm->set_evidence_id($ev_id);
	$lgm->set_direction($d1);
	
	$associated_lgm->set_locus_id($locus_id);
	$associated_lgm->set_evidence_id($ev_id);
	$associated_lgm->set_direction($d2);
	diag("Stored: locus $locus_id (direction=$d1) is $relationship of locus $associated_locus_id (direction=$d2)\n\n");
	diag("conflict: locus $associated_locus_id (direction=$d1) id $relationship of locus $locus_id (direction=$d2)\n\n");
	$locusgroup= $lgm->find_or_create_group($relationship_id, $associated_lgm); #this should return undef!

	is($locusgroup, undef, "Store conflict test");
    };
    if ($@) { print STDERR "Store conflict eval failed! \n" . $@ . "\n"; } 
#####################################
    #non-directional relationships
##############
    #6.
    diag("Store non-directional group test\n");
    ##No group exists for any of the loci with this relationship type
    ##then a new group will be created and both loci added to the group.
    $relationship= 'Complex';
    $rel_cvterm=CXGN::Chado::Cvterm->new_with_term_name($dbh, $relationship, $rel_cv->get_cv_id());
    $relationship_id= $rel_cvterm->get_cvterm_id();
    
    $lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    $associated_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    
    ##########
    
    $lgm->set_locus_id($locus_id);
    $lgm->set_evidence_id($ev_id);
    
    $associated_lgm->set_locus_id($associated_locus_id);
    $associated_lgm->set_evidence_id($ev_id);
    
    $locusgroup= $lgm->find_or_create_group($relationship_id, $associated_lgm); #create a new locus group locus1->homolog-locus2
   
    $lg_id= $locusgroup->get_locusgroup_id();
    $lgm->set_locusgroup_id($lg_id);
    $associated_lgm->set_locusgroup_id($lg_id);
    
    $lgm_id= $lgm->store();           
    $algm_id=$associated_lgm->store(); 
       

    $re_lgm= CXGN::Phenome::LocusgroupMember->new($schema, $lgm_id);
    is($re_lgm->get_locus_id(), $locus_id, "Locus id test");
    is($re_lgm->get_locusgroup_id(), $locusgroup->get_locusgroup_id(), "Locusgroup id test");
    is($re_lgm->get_evidence_id(), $ev_id, "evidence id test");
    is($re_lgm->get_locusgroup()->get_relationship_id(), $relationship_id, "Relationship id test");
    
    
    ##One common group already exists for any of these loci with the given relationship type 
    ##then  the non-existing locus will be added to the group of the other locus
    #Store locus1 homolog of locus2
    #store locus3 homolog of locus1
    # locus3 should be added to the group of locus1&2
    diag("Testing adding member to an existing group!\n");
    
    $lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    $associated_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    
    ##########
    
    $lgm->set_locus_id($locus_id);
    $lgm->set_evidence_id($ev_id);
    
    $associated_locus_id= 3;
    $associated_lgm->set_locus_id($associated_locus_id);
    $associated_lgm->set_evidence_id($ev_id);
    
    my $exists_locusgroup= $lgm->find_or_create_group($relationship_id, $associated_lgm); #this group should exist!
   
    my $exists_lg_id= $exists_locusgroup->get_locusgroup_id();
    is($exists_lg_id, $lg_id, "Locus group exists test");
    is($exists_locusgroup->get_locusgroup_name(), $locusgroup->get_locusgroup_name(), "Locusgroup name test");
    
    $lgm->set_locusgroup_id($exists_lg_id);
    $associated_lgm->set_locusgroup_id($exists_lg_id);
    
    $stored_lgm_id= $lgm->store();     #this one exists      
    $algm_id=$associated_lgm->store();  #this one is new
    
    is($stored_lgm_id, $lgm_id, "Locus member exists test");
   

    $re_lgm= CXGN::Phenome::LocusgroupMember->new($schema, $algm_id);
    is($re_lgm->get_locus_id(), $associated_locus_id, "Locus id test");
    is($re_lgm->get_locusgroup_id(), $exists_locusgroup->get_locusgroup_id(), "Locusgroup id test");
    is($re_lgm->get_evidence_id(), $ev_id, "evidence id test");
    is($re_lgm->get_locusgroup()->get_relationship_id(), $relationship_id, "Relationship id test");
    
##########
    #7 Merge 2 groups 
    #The new link creates a new connection between 2 existing groups.
    #The 2 groups will be merged, all members will get the id of the first group, and the latter group will be obsolete.
    
    #first create a group with 2 new members
    $new_locus_id= 4;
    $associated_locus_id=5;
    diag("Testing merging 2  groups!\n");
    
    my $new_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    $associated_lgm = CXGN::Phenome::LocusgroupMember->new($schema);
    
    ##########
    
    $new_lgm->set_locus_id($new_locus_id);
    $new_lgm->set_evidence_id($ev_id);
    
    $associated_lgm->set_locus_id($associated_locus_id);
    $associated_lgm->set_evidence_id($ev_id);
    
    $new_locusgroup= $new_lgm->find_or_create_group($relationship_id, $associated_lgm); #this should create a new group!
   
    $new_lg_id= $new_locusgroup->get_locusgroup_id();
       
    $new_lgm->set_locusgroup_id($new_lg_id);
    $associated_lgm->set_locusgroup_id($new_lg_id);
    
    my $new_lgm_id= $new_lgm->store();     #this one exists      
    $algm_id=$associated_lgm->store();  #this one is new
    
    #now make the connection between the new group(loci 4&5) and the previous one (loci 1&2&3)
    #by linking loci 4&1
    my $merged_group= $new_lgm->find_or_create_group($relationship_id, $lgm) ;# find the 2 groups, call merge_groups
    
    @members= $merged_group->get_locusgroup_members();
    foreach (@members) { print $_->get_column('locus_id') . "\n" ; }
    # check if group1 is obsolete
    #check if all members are in the 2nd group 
    
    is(scalar(@members) , 5, "merged members test");
    my $ob_group = CXGN::Phenome::LocusGroup->new($schema, $new_locusgroup->get_locusgroup_id());
    
    is($ob_group->get_obsolete(), '1', "Merged group " . $ob_group->get_locusgroup_id() . " obsolete=true test");
    is($merged_group->get_obsolete(), '0', "Merged group " . $merged_group->get_locusgroup_id() . "obsolete=false test");
    
##########################
};

######ok (@term_list == 2, "get_parents");

if ($@) { 
    print STDERR "An error occurred: $@\n";
}

# rollback in any case
$dbh->rollback();

#reset locusgroup table sequence
if ($last_lg_id) {
    $dbh->do("SELECT setval ('phenome.locusgroup_locusgroup_id_seq', $last_lg_id, true)");
}else {
    $dbh->do("SELECT setval ('phenome.locusgroup_locusgroup_id_seq', 1, false)");
}

#reset the locusgroup_member table sequence
if ($last_lgm_id) {
    $dbh->do("SELECT setval ('phenome.locusgroup_member_locusgroup_member_id_seq', $last_lgm_id, true)");
}else {
    $dbh->do("SELECT setval ('phenome.locusgroup_member_locusgroup_member_id_seq', 1, false)");
}
