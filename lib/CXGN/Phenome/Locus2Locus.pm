
=head1 NAME

CXGN::Phenome::Locus2Locus - a class to describe certain relationships between loci.

=head1 DESCRIPTION

This class can be used to describe locus to locus relationships as defined in the locus2locus controlled vocabulary. Examples of relationships are: regulation, binding, interaction, process, etc.

=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>
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

package CXGN::Phenome::Locus2Locus;

use base qw | CXGN::DB::ModifiableI |;

=head2 new()

 Usage:        my $l2l = CXGN::Phenome::Locus2Locus->new($dbh, $locus2locus_id)
 Desc:         generates a new Locus2Locus object
 Args:         a database handle and a locus_id. If locus_id is omitted, an
               empty locus2locus object is created.
 Side Effects: accesses the database.

=cut

sub new { 
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class-> SUPER::new($dbh);
    
    if ($id) { 
	$self->set_locus2locus_id($id);
	$self->fetch();
    }
    
    return $self;
    
}

=head2 fetch

 Usage:        $locus2locus->fetch()
 Desc:         populates the object from the database
 Ret:          nothing
 Args:         
 Side Effects: accesses the database. The locus2locus_id will be
               set to undef if the locus2locus_id property designates
               a locus that does not exist.

=cut

sub fetch {
    my $self = shift;
    my $phenome = $self->get_dbh()->qualify_schema("phenome");
    my $query = "SELECT locus2locus_id, subject_id, object_id, relationship_id, evidence_id, reference_id, sp_person_id, modified_date, create_date, obsolete FROM $phenome.locus2locus WHERE  locus2locus_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus2locus_id());
    
    while (my ($locus2locus_id, $subject_id, $object_id, $relationship_id, $evidence_id, $reference_id, $sp_person_id, $modified_date, $create_date, $obsolete) = $sth->fetchrow_array()) { 
	$self->set_locus2locus_id($locus2locus_id);
	$self->set_subject_id($subject_id);
	$self->set_object_id($object_id);
	$self->set_relationship_id($relationship_id);
	$self->set_evidence_id($evidence_id);
	$self->set_reference_id($reference_id);
	$self->set_sp_person_id($sp_person_id);
	$self->set_modification_date($modified_date);
	$self->set_create_date($create_date);
	$self->set_obsolete($obsolete);
    }
}

=head2 store
    
 Usage:        $locus2locus->store()
 Desc:         performs an insert if the locus2locus_id property
               is undefined, otherwise performs an update.
 Ret:          the locus2locus_id of the updated or inserted row.
 Args:         none
 Side Effects: modifies the database content

=cut

sub store {
    print STDERR "Locus2Locus store function::::\n";
    my $self = shift;
    my $phenome = $self->get_dbh()->qualify_schema("phenome");
    if ($self->get_locus2locus_id()) { 
	print STDERR "Locus2Locus store about to update...\n";
	my $query = "UPDATE $phenome.locus2locus SET
                     subject_id=?, object_id=?, relationship_id=?, evidence_id=?, reference_id=?, sp_person_id=?, modified_date=now()
                     WHERE locus2locus_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute( $self->get_subject_id(),
		       $self->get_object_id(),
		       $self->get_relationship_id(),
		       $self->get_evidence_id(),
		       $self->get_reference_id(),
		       $self->get_sp_person_id(),
		       $self->get_locus2locus_id()
		       );
	return $self->get_locus2locus_id();
    }
    else { 
	print STDERR "Locus2Locus about to store a new locus2locus. Subject_id = " . $self->get_subject_id . "object_id = " . $self->get_object_id . "\n";
	my $query = "INSERT INTO $phenome.locus2locus (subject_id, object_id, relationship_id, evidence_id, reference_id, sp_person_id, obsolete, modified_date, create_date) VALUES (?, ?, ?, ?, ?, ?, 'f', ?, now())";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute( $self->get_subject_id(),
		       $self->get_object_id(),
		       $self->get_relationship_id(),
		       $self->get_evidence_id(),
		       $self->get_reference_id(),
		       $self->get_sp_person_id(),
		       $self->get_modification_date()
		       );
	my $locus2locus_id = $self->get_currval("$phenome.locus2locus_locus2locus_id_seq");
	$self->set_locus2locus_id($locus2locus_id);
	return $locus2locus_id;
    }
}

=head2 obsolete

 Usage: $self->obsolete()
 Desc:  set to obsolete a locus2locus relationship
 Ret:   nothing
 Args:  none
 Side Effects: accesses  the database 
 Example: 

=cut

sub obsolete {
    my $self=shift;
    my $l2l_id= $self->get_locus2locus_id();
    my $query = "UPDATE phenome.locus2locus SET obsolete='t' WHERE locus2locus_id = ? ";
    my $sth= $self->get_dbh()->prepare($query);
    if ($l2l_id)  {
	$sth->execute($l2l_id);
    }else {
	warn "trying to obsolete a locus2locus_id that hasn't been stored yet!\n";
    }
}


=head2 accessors get_locus2locus_id, set_locus2locus_id

 Usage:        my $locus2locus_id = $locus2locus->get_locus2locus_id()
 Desc:         the locus2locus_id accessors
 Property:     locus2locus_id is the primary key of the locus2locus table
 Side Effects: if the locus2locus_id is changed, a different row in the
               database may be updated.
 Example:      

=cut

sub get_locus2locus_id {
  my $self = shift;
  return $self->{locus2locus_id}; 
}

sub set_locus2locus_id {
  my $self = shift;
  $self->{locus2locus_id} = shift;
}


=head2 accessors get_subject_id, set_subject_id

 Usage:    
 Desc:
 Property:     the locus_id of the first locus of the 
               relationship being described by this row.
 Side Effects:
 Example:

=cut

sub get_subject_id {
  my $self = shift;
  return $self->{subject_id}; 
}

sub set_subject_id {
  my $self = shift;
  $self->{subject_id} = shift;
}
=head2 accessors get_object_id, set_object_id

 Usage:
 Desc:         the locus_id of the second locus of the 
               relationship being described by this row.
 Property
 Side Effects:
 Example:

=cut

sub get_object_id {
  my $self = shift;
  return $self->{object_id}; 
}

sub set_object_id {
  my $self = shift;
  $self->{object_id} = shift;
}

=head2 function get_relationship

 Usage:
 Desc:         returns the CXGN::Chado::Cvterm object
               that describes this relationship
 Property:     
 Side Effects:
 Example:

=cut

sub get_relationship {
  my $self = shift;
  return CXGN::Chado::Cvterm->new($self->get_dbh(), $self->get_relationship_id());
}


=head2 accessors get_relationship_id, set_relationship_id

 Usage:
 Desc:
 Property:     the id that designates the cvterm of the 
               relationship.
 Side Effects:
 Example:

=cut

sub get_relationship_id {
  my $self = shift;
  return $self->{relationship_id}; 
}

sub set_relationship_id {
  my $self = shift;
  $self->{relationship_id} = shift;
}


=head2 accessors get_evidence

 Usage:
 Desc:         returns a CXGN::Chado::Cvterm object that describes 
               the evidence code of the locus to locus relationship.

=cut

sub get_evidence {
  my $self = shift;
  return CXGN::Chado::Cvterm->new($self->get_dbh(), $self->get_evidence_id());
}

=head2 accessors get_evidence_id, set_evidence_id

 Usage:
 Desc:
 Property:     the id of the CXGN::Chado::Cvterm that describes
               the evidence code of the locus to locus relationship.
 Side Effects:
 Example:

=cut

sub get_evidence_id {
  my $self = shift;
  return $self->{evidence_id}; 
}

sub set_evidence_id {
  my $self = shift;
  $self->{evidence_id} = shift;
}


=head2 function get_reference

 Usage:        my $pub = $locus2locus->get_reference();
 Desc:         returns the associated publication object.
               call get_reference_id if only the reference_id 
               is needed.
 Property:     CXGN::Chado::Publication
 Side Effects: connects to the database.

=cut

sub get_reference {
  my $self = shift;
  return CXGN::Chado::Publication->new($self->get_dbh(), $self->get_reference_id());
}



=head2 accessors get_reference_id, set_reference_id

 Usage:        my $reference_id = $locus2locus->get_reference_id()
 Desc:         retrieves the associated reference id. see
               get_reference() to retrieve the corresponding object.
 Property:     the reference id [integer]
 Side Effects:
 Example:

=cut

sub get_reference_id {
  my $self = shift;
  return $self->{reference_id}; 
}

sub set_reference_id {
  my $self = shift;
  $self->{reference_id} = shift;
}



=head2 get_cvterm_name

 Usage: $self->get_cvterm_name($dbxref_id)
 Desc:  find the cvterm_name of a dbxref_id
 Ret:   a string
 Args:  dbxref_id
 Side Effects: 
 Example:

=cut

sub get_cvterm_name {
    my $self=shift;
    my $dbxref_id= shift;
    my $dbxref= CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
    my $cvterm_name= $dbxref->get_cvterm_name();
    return $cvterm_name;
}

=head2 create_schema

 Usage:        CXGN::Phenome::Locus2Locus::create_schema($dbh)
 Desc:         creates the schema in the database associated with $dbh.
 Ret:          nothing
 Args:         a CXGN::DB::Connection object
 Side Effects: changes the database structure.

=cut

sub create_schema { 
    my $dbh = shift;
    my $create = "CREATE TABLE phenome.locus2locus (
                   locus2locus_id serial primary key,
                   subject_id bigint references phenome.locus,
                   object_id bigint references phenome.locus,
                   relationship_id bigint references public.dbxref,
                   evidence_id bigint references public.dbxref,
                   reference_id bigint references public.dbxref,
                   sp_person_id bigint references sgn_people.sp_person,
                   obsolete boolean default 'f',
                   modified_date timestamp with time zone,
                   create_date timestamp with time zone default now()
                  )";

    $dbh->do($create);

    my $grant1 = "GRANT SELECT, UPDATE, INSERT ON phenome.locus2locus TO web_usr";
    $dbh->do($grant1);
    
    my $grant2 = "GRANT SELECT, UPDATE, INSERT ON phenome.locus2locus_locus2locus_id_seq TO web_usr";
    $dbh->do($grant2);

    print STDERR "Committing...\n";

    $dbh->commit();

    print STDERR "Done.\n";
    
}

    

return 1;
