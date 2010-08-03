package CXGN::Phenome::LocusgroupMember;

=head1 NAME

CXGN::Phenome::LocusgroupMember - a class to describe locus members of locusgroups.

=head1 DESCRIPTION

This class can be used to describe loci members of locusgroups as defined in the "Locus Relationship"  controlled vocabulary. Examples of relationships are: regulation, binding, interaction, process, etc.
Members of locus groups have evidence code (see cv 'evidence_code')

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=head1 METHODS

This class implements the following methods:

=cut

use strict;
use warnings;
use CXGN::Phenome::Locus;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Publication;
use CXGN::Chado::Dbxref;
use Carp;
use base qw / CXGN::DB::Object /;


=head2 new

  Usage: my $lg = CXGN::Phenome::locusgroupMember->new($schema, $lgm_id);
  Desc:
  Ret: a CXGN::Phenome::LocusgroupMember object
  Args: a $schema a DBIC schema object,
        $lgm_id, if omitted, an empty  object is created.
  Side_Effects: accesses the database

=cut

sub new {
    my $class = shift;
    my $schema = shift;
    my $id = shift;
    
    ### First, bless the class to create the object and set the schema into the object.
    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);
    my $lgm;
    if ($id) {
	$lgm = $self->get_resultset('LocusgroupMember')->find({ locusgroup_member_id => $id }); #a row object
    } else {
	$self->debug("Creating a new empty LocusgroupMember object! " . $self->get_resultset('LocusgroupMember'));
	$lgm = $self->get_resultset('LocusgroupMember')->new({});   ### Create an empty object; 
    }
    ###It's important to set the object row for using the accesor in other class functions
    $self->set_object_row($lgm);
    ######
    
    return $self;
}



=head2 store

 Usage: $self->store()
 Desc:  store a new locusgroup_member
        
        Do nothing if locusgroup_member already associated with the group
        If member obsolete = 't' , set obsolete ='f'
 Ret:   database id
 Args:  none
 Side Effects: 
 Example:

=cut

sub store {
    my $self=shift;
    my $id= $self->get_locusgroup_member_id();
    my $schema=$self->get_schema();
    
    #no locusgroup_member_id . 
    
    #or maybe better off to 'find' and then use 'update_or_create'
    if (!$id) { 
	my $exists=$self->exists_in_database();
	if (!$exists) {
	    my $new_row=$self->get_object_row->insert();
	    $id=$new_row->locusgroup_member_id();
	    $self->set_locusgroup_member_id($id);
	    $self->d( "LocusgroupMember inserted a new locus  " . $self->get_locus_id() ." database_id = $id\n");
	}else { 
	    $self->set_locusgroup_member_id($exists);
	    # check is it's obsolete! 
	    my $existing_lgm=$self->get_resultset('LocusgroupMember')->find($exists);
	    if ($existing_lgm->obsolete()) {
		$existing_lgm->update({ obsolete => 'f' , modified_date=> \ 'now()'} );
		$self->d("Unobsoleting locusgroup_member $exists! ");
	    }
	    $self->d( "Locus id " . $self->get_locus_id()  . " is already a member of group " . $self->get_locusgroup_id . "!\n");
	} 
    }else { # id exists
	$self->d( "Updating existing locusgroup_member_id $id\n");
	$self->get_object_row()->update();
	$self->get_object_row()->update({ obsolete => 'f', modified_date=> \ 'now()' } ) ;
    }
    return $self->get_locusgroup_member_id();
}

######
######
   
=head2 find_or_create_group

 Usage: $self->find_or_create_group($relationship_id, $associated_locusgroup_member)
 Desc:  see if the locus already belongs to a group based on the relationship name
        See first if the locus has a 'direction' (is it an object or a subject?)
        Then check if the 2 loci are already stored in a group (then do nothing)
        Or if there is a conflict 
        (trying to store L1=object L2=Subject, while group L1(subject)-L2(object) already exists).
        If 'direction' is not stored then check both loci for existing group membership.
        If 2 groups are retrieved, these might have to be merged! 
        (group1=L1-L2, group2=L3-L4, trying now to store L1-L4 will cause merging of groups 1 and 2 (see $self->merge_groups).
        
 Ret:   a CXGN::Phenome::LocusGroup object
 Args:  cvterm_id of the relationship, the locusgroup_member we want to add to the group
 Side Effects: stores a new locusgroup if one does not exist, merge groups if inferred.
 Example:

=cut

sub find_or_create_group {
    my $self=shift;
    my $relationship_id=shift || croak("FUNCTION PARAMETER ERROR: Must pass a relationship_id to find_or_create_group!!");
    my $lgm=shift || croak("FUNCTION PARAMETER ERROR: Must pass a LocusgroupMember object as a second parameter to find_or_create_group!");

    my $direction = $self->get_direction(); # if this is a subject or an object the group can only have 2 members! 
    my $locus_id= $self->get_locus_id();
    if ($locus_id == $lgm->get_locus_id()) {
	
	warn "Cannot associate a locus to itself! (locus_id = $locus_id)";
	return undef;
    }
    my $relationship=CXGN::Chado::Cvterm->new($self->get_dbh(), $relationship_id)->get_cvterm_name();
    my @groups = ();
   
    # Directional relationships can have only 2 members. 
    #Need to check if the group already exists and if there is a conflict.
    my $directional_group; 
    if (!$direction) { 
	@groups=$self->get_resultset('Locusgroup')->search( {
	    -and => [
		 -or => [
		      locus_id => $locus_id,
		      locus_id => $lgm->get_locus_id(),
		 ],
		 relationship_id =>$relationship_id,
		],},
	      {join =>  'locusgroup_members',
	       distinct =>1
	      }, #### Had to chage 'belongs_to' in Schema::LocusgroupMember 
	    );
    }else { # direction is defined
	@groups = $self->get_resultset('Locusgroup')->search(
	    { locus_id        => $locus_id , 
	      relationship_id => $relationship_id
	    },
	    {join => 'locusgroup_members' }
	    );
	#now check which of the groups has the 2 directional members... 
	foreach (@groups) {
	    my $group_id= $_->locusgroup_id();
	    my @members= $_->locusgroup_members();
	    
	    #check if there are 2 members in each group
	    warn("Check the database ! This group " . $_->locusgroup_name() . " should have 2 members!") if (scalar(@members)!=2);
	    $self->d( "Group ". $_->locusgroup_name() . " has " . scalar(@members) . "members! \n"); 
	    #find the correct group number for the 2 members
	    my $member1= $members[0];
	    my $member2= $members[1];
	    
	    my %m1= (locus_id => $member1->get_column('locus_id'),
		     direction=> $member1->direction()
		);
	    my %m2= (locus_id => $member2->get_column('locus_id'),
		     direction=> $member2->direction()
		);

	    if (($m1{locus_id} == $locus_id) & ($m1{direction} eq $direction)) { 
		if  (($m2{locus_id} == $lgm->get_locus_id()) & ($m2{direction} eq $lgm->get_direction()) ) {
		    $directional_group = $_;
		    $self->d( "Found group $group_id!! \n"); #############
		    
		}
	    }
	    if (($m2{locus_id} == $locus_id) & ($m2{direction} eq $direction)) { 
		if  (($m1{locus_id} == $lgm->get_locus_id()) & ($m1{direction} eq $lgm->get_direction()) ) {
		    $directional_group = $_;
		    $self->d( "Found group $group_id!! \n"); ##########
		}
	    }
	    if (!$directional_group) { # the 2 loci are not in the same directional group. Need to create a new one! 
		$self->d("creating a new directional locus group ! "); ############
		@groups=();
	    }
	    
           #check for conflicts
	    $self->d("Checking for conflicts: (locus_id = $locus_id, direction=$direction. Associated locus_id= ". $lgm->get_locus_id . " direction = ". $lgm->get_direction() );
	    $self->d( "locus1=" . $m1{locus_id} . " direction1=" . $m1{direction} . " .Locus2 = " . $m2{locus_id} . "direction2= " . $m2{direction} ); 
	    if (($m1{locus_id} == $locus_id) & ($m1{direction} eq $lgm->get_direction()) ) { 
		if  (($m2{locus_id} == $lgm->get_locus_id()) & ($m2{direction} eq $direction)) {
		    warn("Found conflict! Trying to store locus $locus_id as $direction and locus ". $lgm->get_locus_id() . " as " . $lgm->get_direction() . "\n while found group $group_id with locus " . $m1{locus_id} . " and direction " . $m1{direction} . "\nand locus "  . $m2{locus_id} . " and direction " . $m2{direction} . " Exiting!!");
		    return undef;   
		}
	    }elsif  (($m2{locus_id} == $locus_id) & ($m2{direction} eq $lgm->get_direction()) ) {
		    warn("Found conflict! Trying to store locus $locus_id as $direction and locus ". $lgm->get_locus_id() . " as " . $lgm->get_direction() . "\n while found group $group_id with locus " . $m1{locus_id} . " and direction " . $m1{direction} . "\nand locus "  . $m2{locus_id} . " and direction " . $m2{direction} . " Exiting!!");
		    return undef;   
	    }
	}
    }
    
    my $lgo=undef; #if no groups are found
    if ($directional_group ) {  
	$self->d("Found directional group! " . $directional_group->locusgroup_id() ); ######### 
	$lgo= $directional_group;
    }
    elsif ($groups[0]) { 
	$self->d("Found group " . $groups[0]->locusgroup_id() ); #########
	$lgo=$groups[0] ;
    }  #  this will remain if only 1 group is found
    
    if (scalar(@groups) > 1 ) { # if more than 1 group is found then merge the 2
	$self->d("Found " . scalar(@groups) . " groups. Merging!... \n") ; 
	$lgo= $self->merge_groups(@groups); # merging groups returns 1 locusgroup object
    }
    
    my $lg_id;
    $lg_id= $lgo->locusgroup_id() if $lgo; 
    if ($lgo) { $self->d("Locusgroup exists! ID = $lg_id\n"); }
    else { $self->d( "Storing a new locusgroup for locus " . $self->get_locus_id() . " and relationship $relationship!\n"); }
    $lgo= CXGN::Phenome::LocusGroup->new($self->get_schema(), $lg_id); # now the locusgroup is a 2nd level DBIC object
    if (!$lg_id) { 
	$lgo->set_relationship_id($relationship_id);
	$lgo->set_locusgroup_name("locus$locus_id$relationship");
	#add the associated locus_id to the group name for uniqueness of 2-member directional groups
	$lgo->set_locusgroup_name("locus$locus_id$relationship".$lgm->get_locus_id()) if $direction; 
	$lgo->set_sp_person_id($self->get_sp_person_id());
	$lg_id= $lgo->store();
    }
   
    $self->d( "The locusgroup name is " . $lgo->get_locusgroup_name() . "! ID= $lg_id . get_locusgroup_id = " . $lgo->get_locusgroup_id()  . "  !!!\n") ;
    return $lgo;
}

#####
=head2 merge_groups

 Usage:         $self->merge_groups(@groups)
 Desc:          see if 2 groups need to be merged based on common members
                Useful when associating 2 loci which generate a connection between 2 existing groups
 Ret:           a CXGN::Phenome::LocusGroup object
 Args:          a list of groups that need merging  (usually 2)
 Side Effects:  Change the latter group id 
 Example:       Group1: locus1, locus2 (orthologs)
                Group2: locus3, locus4 (orthologs)
                New network: locus1, locus3 (orthologs) - 
                now groups 1 and 2 need merging (but only if the relationship is not directional! 
                (i.e. downstream, inhibition, activation)
                This is being checked by looking at the 'direction' field, so make sure it's set before storing!  
=cut

sub merge_groups {
    my $self=shift;
    my @groups=@_;
    my %lgs= map{$_->locusgroup_id() => $_}  @groups;
    
    my $group_id = undef;
    my $group1=undef; # this should be the first group stored, which will supersede the later groups
    my $name;
    for my $key (sort {$a<=>$b} keys %lgs) {
	if (!$group_id) {
	    $group_id = $key;
	    $group1=$lgs{$group_id};
	    $name=$group1->locusgroup_name();
	    
	    $self->d( "Update members of all groups to group $name (id = $group_id) \n");
	}else {
	    my $group= $lgs{$key};
	    $self->d( "Merging group " . $group->locusgroup_name() . "(id=" . $group->locusgroup_id . ") with group $name ($group_id)\n");
	    
	    my @members= $group->locusgroup_members();
	    
	    #update the locusgroup_id of the members to the id of the 1st group
	    foreach my $member(@members) { 
		$member->update( {locusgroup_id => $group_id, modified_date=> \ 'now()'  }) ; 
		$self->d("Updated group_id of member " . $member->get_column('locus_id') . "\n");
	    } 
	    
	    #now obsolete the merged groups 
	    $group->update({ obsolete => 't' , modified_date => \ 'now()' } );
	    
	    $self->d( "Set group " . $group->locusgroup_name() . " (id= " . $group->locusgroup_id() . ") to obsolete! \n");
	}
    }
    return $group1;
}


=head2 exists_in_database
    
 Usage: $self->exists_in_database()
 Desc:  check if the locusgroup_member is already associated with the group 
 Ret:   Database id or undef
 Args: none
 Side Effects:
 Example:

=cut

sub exists_in_database {
    my $self=shift;
    my $o = $self->get_resultset('LocusgroupMember')->search(
	{ locus_id        => $self->get_locus_id(),
	  locusgroup_id   => $self->get_locusgroup_id() ,
	  #realtionship_id => $self->get_relationship_id() 
	},
	#{ join => 'locusgroup' }
	)->first();
    return $o->locusgroup_member_id() if $o;
    return undef;
}

=head2 get_locusgroup

 Usage: $self->get_locusgroup()
 Desc:  get the locusgroup object of this member
 Ret:  a CXGN::Phenome::LocusGroup object
 Args: none
 Side Effects: none
 Example:

=cut

sub get_locusgroup {
    my $self=shift;
    return CXGN::Phenome::LocusGroup->new($self->get_schema(), $self->get_locusgroup_id());
}


=head2 obsolete_lgm

 Usage: $self->obsolete_lgm()
 Desc:  set the locusgroupMember to obsolete ('t')
 Ret:   nothing
 Args:  none 
 Side Effects: set modified_date = now()
 Example:

=cut

sub obsolete_lgm {
    my $self=shift;
    $self->get_object_row()->update({ obsolete => 't' , modified_date=> \ 'now()' } );
}


#########move these to CXGN::DB::Object##############

=head2 accessors get_object_row, set_object_row

 Usage: $self->get_object_row() 
        $self->set_object_row( $self->get_schema->resultset($source)->new( {} )  )
 Desc:  get/set a DBIx::Class row object
 Property
 Side Effects:
 Example:

=cut

sub get_object_row {
  my $self = shift;
  return $self->{object_row}; 
}

sub set_object_row {
  my $self = shift;
  $self->{object_row} = shift;
}

=head2 get_resultset

 Usage: $self->get_resultset(ModuleName::TableName)
 Desc:  Get a ResultSet object for source_name 
 Ret:   a ResultSet object
 Args:  a source name
 Side Effects: none
 Example:

=cut

sub get_resultset {
    my $self=shift;
    my $source = shift;
    return $self->get_schema()->resultset("$source");
}



###########accessors. Need to move all to CXGN::DB::Object###############

=head2 accessors get_locusgroup_member_id, set_locusgroup_member_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_locusgroup_member_id {
    my $self = shift;
    return $self->get_object_row()->get_column("locusgroup_member_id"); 
}

sub set_locusgroup_member_id {
    my $self = shift;
    $self->get_object_row()->set_column(locusgroup_member_id => shift);
}

=head2 accessors get_locusgroup_id, set_locusgroup_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_locusgroup_id {
    my $self = shift;
    return $self->get_object_row()->get_column("locusgroup_id"); 
}

sub set_locusgroup_id {
    my $self = shift;
    $self->get_object_row()->set_column(locusgroup_id => shift);
}



=head2 accessors get_locus_id, set_locus_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_locus_id {
    my $self = shift;
    return $self->get_object_row()->get_column("locus_id"); 
}

sub set_locus_id {
    my $self = shift;
    $self->get_object_row()->set_column(locus_id => shift);
}


=head2 accessors get_evidence_id, set_evidence_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_evidence_id {
    my $self = shift;
    return $self->get_object_row()->get_column("evidence_id"); 
}

sub set_evidence_id {
    my $self = shift;
    $self->get_object_row()->set_column(evidence_id => shift);
}

=head2 accessors get_reference_id, set_reference_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_reference_id {
    my $self = shift;
    return $self->get_object_row()->get_column("reference_id"); 
}

sub set_reference_id {
    my $self = shift;
    $self->get_object_row()->set_column(reference_id => shift);
}

=head2 accessors get_direction, set_direction

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_direction {
    my $self = shift;
    return $self->get_object_row()->get_column("direction"); 
}

sub set_direction {
    my $self = shift;
    $self->get_object_row()->set_column(direction => shift);
}



=head2 accessors get_sp_person_id, set_sp_person_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_sp_person_id {
    my $self = shift;
    return $self->get_object_row()->get_column("sp_person_id"); 
}

sub set_sp_person_id {
    my $self = shift;
    $self->get_object_row()->set_column(sp_person_id => shift);
}

=head2 accessors get_create_date, set_create_date

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_create_date {
    my $self = shift;
    return $self->get_object_row()->get_column("create_date"); 
}

sub set_create_date {
    my $self = shift;
    $self->get_object_row()->set_column(create_date => shift);
}

=head2 accessors get_modified_date, set_modified_date

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_modified_date {
    my $self = shift;
    return $self->get_object_row()->get_column("modified_date"); 
}

sub set_modified_date {
    my $self = shift;
    $self->get_object_row()->set_column(modified_date => shift);
}

=head2 accessors get_obsolete, set_obsolete

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_obsolete {
    my $self = shift;
    return $self->get_object_row()->get_column("obsolete"); 
}

sub set_obsolete {
    my $self = shift;
    $self->get_object_row()->set_column(obsolete => shift);
}



###########
return 1;##
###########
