=head1 NAME

CXGN::Phenome::Individual::IndividualDbxrefEvidence 
display evidence codes of ontology annotations associated with an individual 

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut

use CXGN::DB::Connection;
use CXGN::Phenome::Individual; 
use CXGN::Chado::Dbxref::DbxrefI;

package CXGN::Phenome::Individual::IndividualDbxrefEvidence;

use base qw /  CXGN::Chado::Dbxref::EvidenceI   /;



=head2 new

 Usage: my $individual_dbxref_evidence = CXGN::Phenome::Individual::IndividualDbxrefEvidence->new($dbh, $individual_dbxref_evidence_id);
 Desc:
 Ret:    
 Args: $dbh, $individual_dbxref_evidence_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the individual_dbxref_evidence_id of the IndividualDbxrefEvidence object 
    
    my $args = {};  

    my $self=$class->SUPER::new($dbh);   

    $self->set_object_dbxref_evidence_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;

    my $evidence_query = $self->get_dbh()->prepare("SELECT  individual_dbxref_id, relationship_type, evidence_code, evidence_description, evidence_with, reference_id, sp_person_id, updated_by, create_date, modified_date, obsolete FROM phenome.individual_dbxref_evidence WHERE individual_dbxref_evidence_id=?");

    my $individual_dbxref_evidence_id=$self->get_object_dbxref_evidence_id();
         	   
    $evidence_query->execute($individual_dbxref_evidence_id);
    
    my ($individual_dbxref_id, $relationship_type_id, $evidence_code_id, $evidence_description_id, $evidence_with, $reference_id, $sp_person_id, $updated_by, $create_date, $modified_date, $obsolete)=$evidence_query->fetchrow_array();
    $self->set_object_dbxref_id($individual_dbxref_id);
    $self->set_relationship_type_id($relationship_type_id);
    $self->set_evidence_code_id($evidence_code_id);
    $self->set_evidence_description_id($evidence_description_id);
    $self->set_evidence_with($evidence_with);
    $self->set_reference_id($reference_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_updated_by($updated_by);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_obsolete($obsolete);
}



sub store {
    my $self= shift;
    my $obsolete= $self->get_obsolete();
    my $individual_dbxref_evidence_id=$self->get_object_dbxref_evidence_id();
       
    if (!$individual_dbxref_evidence_id) {
	my $query = "INSERT INTO phenome.individual_dbxref_evidence (individual_dbxref_id, relationship_type, evidence_code, evidence_description, evidence_with, reference_id, sp_person_id) VALUES(?,?,?,?,?,?,?)";
	my $sth= $self->get_dbh()->prepare($query);
	
	$sth->execute($self->get_object_dbxref_id(), $self->get_relationship_type_id(), $self->get_evidence_code_id(),$self->get_evidence_description_id(), $self->get_evidence_with(), $self->get_reference_id(), $self->get_sp_person_id() );
	
	$individual_dbxref_evidence_id=  $self->get_dbh()->last_insert_id("individual_dbxref_evidence", "phenome");
	$self->set_object_dbxref_evidence_id($individual_dbxref_evidence_id);
	
    }elsif ($individual_dbxref_evidence_id && $obsolete eq 't') {
	
	my $query = "UPDATE phenome.individual_dbxref_evidence SET relationship_type=?, evidence_code=?, evidence_description=?, evidence_with=?, reference_id=?,  updated_by=?, obsolete='f', modified_date = now() WHERE individual_dbxref_evidence_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_relationship_type_id(), $self->get_evidence_code_id(),$self->get_evidence_description_id(), $self->get_evidence_with(), $self->get_reference_id(), $self->get_updated_by(), $individual_dbxref_evidence_id);
    }
    return $individual_dbxref_evidence_id;
}

=head2 evidence_exists

 Usage: $self->evidence_exists()
 Desc:  find if the evidence details already exists in db 
 Ret:   database id or undef 
 Args:  none
 Side Effects: none
 Example:

=cut

sub evidence_exists {
    my $self=shift;
    my $query = "SELECT individual_dbxref_evidence_id FROM phenome.individual_dbxref_evidence
                 WHERE relationship_type=?
                 AND evidence_code=?
                 AND individual_dbxref_id=?";
    my $sth=$self->get_dbh()->prepare($query);
    print STDERR $self->get_relationship_type_id() . "," . $self->get_evidence_code_id() . "," . $self->get_object_dbxref_id() ."\n\n";
    $sth->execute($self->get_relationship_type_id(), $self->get_evidence_code_id(), $self->get_object_dbxref_id());
    my ($id) = $sth->fetchrow_array();
    return $id || undef;
}


=head2 delete

 Usage: $self->delete()
 Desc:  an alias for $self->obsolete()
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub delete {
    my $self=shift;
    $self->obsolete();
}


=head2 obsolete
    
 Usage: $self->obsolete()
 Desc:  sets to obsolete a individual_dbxref_evidence  
 Ret: nothing
 Args: none
 Side Effects: 
 Example:

=cut

sub obsolete {

    my $self = shift;
    if ($self->get_object_dbxref_evidence_id()) { 
	my $query = "UPDATE phenome.individual_dbxref_evidence SET obsolete='t', modified_date=now(), updated_by=?
                  WHERE individual_dbxref_evidence_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_updated_by(), $self->get_object_dbxref_evidence_id());
	$self->store_history();
    }else { 
	print STDERR  "trying to delete a individual_dbxref_evidence that has not yet been stored to db.\n";
    }    
}		     


=head2 unobsolete

 Usage: $self->unobsolete()
 Desc:  unobsolete an individual_dbxref_evidence  
 Ret: nothing
 Args: none
 Side Effects: 
 Example:

=cut

sub unobsolete {
    my $self = shift;
    if ($self->get_object_dbxref_evidence_id()) { 
	my $query = "UPDATE phenome.individual_dbxref_evidence SET obsolete='f', modified_date=now()
                  WHERE individual_dbxref_evidence_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_object_dbxref_evidence_id());
    }else { 
	print STDERR  "trying to unobsolete an individual_dbxref_evidence that has not yet been stored to db.\n";
    }    
}		     

=head2 get_object_dbxref

 Usage: $self->get_object_dbxref()
 Desc:  get the IndividualDbxref object for this evidence 
 Ret:   IndividualDbxref object
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_object_dbxref {
    my $self=shift;
    return CXGN::Phenome::Individual::IndividualDbxref->new($self->get_dbh(), $self->get_object_dbxref_id());
}

=head2 get_individual_dbxref

 Usage: DEPRECATED 
 Desc: repplaced by get_object_dbxref()
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_individual_dbxref {
    my $self=shift;
    warn "DEPRECATED. Replaced by get_object_dbxref() !";
    return $self->get_object_dbxref();
}


=head2 store_history

 Usage: $self->store_history() . call this function before deleting or updating 
 Desc:  'moves' the record to the individual_dbxref_evidence table
               this is important for allowing future updates of the individual_dbxref_evidence table
               is cases of a individual_dbxref being obsoleted and then being un-obsoleted with a new
               set of evidnce codes and references. The old evidence codes will be kept in the history table
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub store_history {
    my $self=shift;
    if ($self->get_object_dbxref_evidence_id()) { 
	print STDERR "IndividualDbxrefEvidence.pm **** store_history()\n\n";
	my $history_query= "INSERT INTO phenome.individual_dbxref_evidence_history
                            (individual_dbxref_evidence_id, individual_dbxref_id, relationship_type, evidence_code, evidence_description, evidence_with, reference_id, sp_person_id, updated_by,  modified_date, obsolete) 
                            VALUES (?,?,?,?,?,?,?,?,?,?,?) ";
	my $history_sth=$self->get_dbh()->prepare($history_query);
	$history_sth->execute($self->get_object_dbxref_evidence_id(), $self->get_object_dbxref_id(), $self->get_relationship_type_id(), $self->get_evidence_code_id, $self->get_evidence_description_id(), $self->get_evidence_with(), $self->get_reference_id(), $self->get_sp_person_id, $self->get_updated_by(), $self->get_modification_date(),$self->get_obsolete());
	my $id= $self->get_dbh()->last_insert_id("individual_dbxref_evidence_history", "phenome");
	print STDERR "*!*!individual_dbxref_evidence_history_id: $id***\n";
    }else { 
	print STDERR  "trying to store history of a individual_dbxref_evidence that has not yet been stored to db.\n";
    }    
}


=head2 accessors in this class

    individual_dbxref_evidence_id - DEPRECATED . replaced by object_dbxref_evidence_id
    individual_dbxref_id    - DEPRECATED . Replaced by object_dbxref_id
    relationship_type_id
    evidence_code_id
    evidence_description_id
    evidence_description_id
    evidence_with
    reference_id


=cut

sub get_individual_dbxref_evidence_id {
  my $self=shift;
  warn "DEPRECATED. Replaced by get_object_dbxref_evidence_id() ! ";
  return $self->get_object_dbxref_evidence_id();

}

sub set_individual_dbxref_evidence_id {
  my $self=shift;
    warn "DEPRECATED. Replaced by set_object_dbxref_evidence_id() ! ";
  
  $self->{object_dbxref_evidence_id}=shift;
}

sub get_individual_dbxref_id {
  my $self=shift;
  warn "DEPRECATED. Replaced by get_object_dbxref_id() ! ";

  return $self->get_object_dbxref_id();

}

sub set_individual_dbxref_id {
  my $self=shift;
  warn "DEPRECATED. Replaced by set_object_dbxref_id() ! ";

  $self->{object_dbxref_id}=shift;
}


##########
return 1;#
##########
