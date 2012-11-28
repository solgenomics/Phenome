
=head1 NAME

CXGN::Phenome::LocusGroup - a class to describe groups of related  loci.

=head1 DESCRIPTION

This class can be used to describe groups of related loci as defined in the "Locus Relationship"  controlled vocabulary. Examples of relationships are: regulation, binding, interaction, process, etc.

=head1 AUTHOR

Naama Menda <nm249@cornell.edu>

=head1 METHODS

This class implements the following methods:

=cut


use strict;
use CXGN::DB::Connection;
use CXGN::Phenome::Locus;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Publication;
use CXGN::Chado::Dbxref;
use CXGN::Phenome::LocusgroupMember;

package CXGN::Phenome::LocusGroup;

use base qw / CXGN::DB::Object /;


=head2 new

  Usage: my $lg = CXGN::Phenome::locusGroup->new($schema, $lg_id);
  Desc:
  Ret: a CXGN::Phenome::LocusGroup object
  Args: a $schema a schema object
        $lg_id, if omitted, an empty  object is created.
  Side_Effects: accesses the database, check if exists the database columns that this object use.  
=cut

sub new {
    my $class = shift;
    my $schema = shift;
    my $id = shift;

    ### First, bless the class to create the object and set the schema into the object.
    my $self = $class->SUPER::new($schema);
    $self->set_schema($schema);
    my $lg;
    if ($id) {
	($lg) = $self->get_resultset('Locusgroup')->search({ locusgroup_id => $id }); #a row object
    } else {
	$self->debug("Creating a new empty Locusgroup object! " . $self->get_resultset('Locusgroup'));
	$lg = $self->get_resultset('Locusgroup')->new({});   ### Create an empty object; 
    }
    ###It's important to set the object row for using the accesor in other class functions
    $self->set_object_row($lg);
    ######
    
    return $self;
}



=head2 store

 Usage: $self->store()
 Desc:  store a new locusgroup
        Update if has a locusgroup_id
        Do nothing if locusgroup_name exists
 Ret:   database id
 Args:  none
 Side Effects: 
 Example:

=cut

sub store {
    my $self=shift;
    my $id= $self->get_locusgroup_id();
    my $schema=$self->get_schema();
    
    #no locusgroup id . Check first if the name exists in the database
    #SEE IF find_or_create can take care of this , since locusgroup_name is unique.
    #or maybe better off to 'find' and then use 'update_or_create'
    if (!$id) { 
	#my $exists=$self->exists_in_database();
	#$self->d("id=$id, exists=$exists!");
	#if (!$exists) {
	    my $new_row= $self->get_object_row->insert();
	    $id= $new_row->locusgroup_id();
	    $self->set_locusgroup_id($id);
	    $self->d("Inserted a new Locusgroup! ID = $id ");
	#}else { 
	#    $self->d("Locusgroup " . $self->get_locusgroup_name()  . " exists in database !");
	#} 
    }else { # id exists
	$self->get_object_row()->update();
        $self->d("Updating Locusgroup!");
    }
    return $self->get_locusgroup_id();
}



=head2 get_locusgroup_members

 Usage: $self->get_locusgroup_members()
 Desc:  find all the locusgroup_members 
 Ret:   list of locusgroup_members row objects 
 Args:  none
 Side Effects:
 Example:

=cut

sub get_locusgroup_members {
    my $self=shift;
    return $self->get_object_row()->locusgroup_members();
}

=head2 get_cxgn_members

 Usage: $self->get_cxgn_members()
 Desc:  find all the locusgroup_members
 Ret:   hashref with keys of loci ids , and values of hashrefs with the following keys:        locus-> L<CXGN::Phenome::Locus> object
        evidence-> a cvterm name of the evidence code
        reference-> html link to a publication page if applicable
 Args:  none
 Side Effects:
 Example:

=cut

sub get_cxgn_members {
    my $self=shift;
    my $loci= {};
    my $members = $self->get_locusgroup_members;
    while (my $member = $members->next ) {
        my $evidence_id = $member->evidence_id;
        my $evidence_cvterm = CXGN::Chado::Cvterm->new($self->get_dbh, $evidence_id);
        my $evidence = $evidence_cvterm->name;
        my $reference_id = $member->reference_id;
        my $reference_pub = CXGN::Chado::Publication->new($self->get_dbh, $reference_id);
        my $mini_ref = $reference_pub->print_mini_ref;
        my $ref_link = $reference_id ?  qq|<a href="/chado/publication.pl?pub_id=$reference_id">$mini_ref</a> | : undef;
        my $locus_id = $member->get_column('locus_id');
        my $locus =  CXGN::Phenome::Locus->new($self->get_dbh, $locus_id);
        $loci->{$locus_id}->{locus} = $locus;
        $loci->{$locus_id}->{evidence} = $evidence;
        $loci->{$locus_id}->{reference} = $ref_link;
    }
    return $loci;
}


=head2 exists_in_database

 Usage: $self->exists_in_database()
 Desc:  check if the locusgroup_name exists in the locusgroup table
 Ret:   Database id or undef
 Args: none
 Side Effects:
 Example:

=cut

sub exists_in_database {
    my $self=shift;
    my $locusgroup_name = shift;
    if (!$locusgroup_name) { $locusgroup_name = $self->get_locusgroup_name; }
    my $o = $self->get_resultset('Locusgroup')->search({
	locusgroup_name  => { 'ilike' => $locusgroup_name } } )->single(); #  ->single() for retrieving a single row (there sould be only one locusgroup_name entry)
    return $o->locusgroup_id() if $o;
    return undef;
}


=head2 get_relationship_name

 Usage: $self->get_relationship_name()
 Desc:  find the cvterm name of the relationship of this group
 Ret:   a string
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_relationship_name {
    my $self=shift;
    my $cvterm=CXGN::Chado::Cvterm->new($self->get_dbh(), $self->get_relationship_id);
    return $cvterm->get_cvterm_name();
}



=head2 count_members

 Usage: $locusgroup->count_members()
 Desc:  find the number of unobsoleted members
 Ret:    an integer, or undef if the resultset is undef
 Args:   none
 Side Effects:
 Example:

=cut

sub count_members {
    my $self=shift;
    my $rs= $self->get_resultset('LocusgroupMember')->search(
	{ locusgroup_id   => $self->get_locusgroup_id() ,
	  obsolete => 0 
	} );
    return $rs->count() if $rs;
    return undef;
}



=head2 add_member

 Usage: $self->add_member($locusgroup_member)
 Desc:  Add a member to the group
 Ret:   a locusgroup_member_id
 Args:  CXGN::Phenome::LocusgroupMember object
 Side Effects: call store function in LocusgroupMember
 Example:

=cut

sub _add_member {
    my $self=shift;
    my $lgm=shift;
    $lgm->set_locusgroup_id($self->get_locusgroup_id());
    return $lgm->store();
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



=head2 accessors get_locusgroup_name, set_locusgroup_name

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_locusgroup_name {
    my $self = shift;
    return $self->get_object_row()->get_column("locusgroup_name"); 
}

sub set_locusgroup_name {
    my $self = shift;
    $self->get_object_row()->set_column(locusgroup_name => shift);
}

=head2 accessors get_relationship_id, set_relationship_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_relationship_id {
    my $self = shift;
    return $self->get_object_row()->get_column("relationship_id"); 
}

sub set_relationship_id {
    my $self = shift;
    $self->get_object_row()->set_column(relationship_id => shift);
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


=head2 create_schema

 Usage: CXGN::Phenome::LocusGroup::create_schema($dbh);
 Desc:  create locusgroup and locusgroup_member tables. 
        Grant permissions to web_usr
 Ret:   nothing
 Args:  CXGN::DB::Connection->new()
 Side Effects: 
 Example:

=cut

sub create_schema {
    my $dbh=shift;
    my @q= ("CREATE TABLE phenome.locusgroup (
            locusgroup_id serial NOT NULL PRIMARY KEY,
            locusgroup_name varchar (255) UNIQUE,
            relationship_id integer REFERENCES public.cvterm(cvterm_id),
            sp_person_id integer REFERENCES sgn_people.sp_person(sp_person_id), 
            create_date  timestamp with time zone  default now(),
            modified_date timestamp with time zone,
            obsolete boolean DEFAULT false
            )",
	    
	    "CREATE TABLE phenome.locusgroup_member (
             locusgroup_member_id serial NOT NULL PRIMARY KEY,
             locusgroup_id integer REFERENCES phenome.locusgroup,
             locus_id integer REFERENCES phenome.locus ON DELETE CASCADE, 
             direction  varchar(16) CHECK (direction IN ('subject', 'object', '')),
             evidence_id integer REFERENCES public.cvterm(cvterm_id),
             reference_id integer REFERENCES public.dbxref(dbxref_id), 
             sp_person_id integer REFERENCES sgn_people.sp_person(sp_person_id), 
             create_date  timestamp with time zone  default now(),
             modified_date timestamp with time zone,
             obsolete boolean DEFAULT false,
             CONSTRAINT locusgroup_member_key UNIQUE (locus_id, locusgroup_id)
             )",
	    "GRANT SELECT, UPDATE, INSERT ON phenome.locusgroup TO web_usr",
	    "GRANT SELECT, UPDATE ON phenome.locusgroup_locusgroup_id_seq TO web_usr",
	    "GRANT SELECT, UPDATE, INSERT ON phenome.locusgroup_member TO web_usr",
	    "GRANT SELECT, UPDATE ON phenome.locusgroup_member_locusgroup_member_id_seq TO web_usr"
	);
    foreach (@q) {
	$dbh->do($_);
    }
    
    print STDERR "Committing...\n";
    $dbh->commit();
    print STDERR "Done.\n";
}

###########
return 1;##
###########
