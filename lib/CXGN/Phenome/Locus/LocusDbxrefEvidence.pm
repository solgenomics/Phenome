=head1 NAME

CXGN::Phenome::Locus::LocusDbxrefEvidence 
display evidence codes of ontology annotations associated with a locus 

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut

use CXGN::DB::Connection;
use CXGN::Phenome::Locus; 
use CXGN::Phenome::LocusDbxref;
use CXGN::Chado::Cvterm;
use CXGN::Chado::Dbxref;
use CXGN::Chado::Dbxref::EvidenceI;
use CXGN::Chado::Dbxref::DbxrefI;

package CXGN::Phenome::Locus::LocusDbxrefEvidence;

#use base qw / CXGN::Phenome::Main CXGN::Phenome::Locus CXGN::Chado::Cvterm CXGN::Chado::Dbxref CXGN::DB::ModifiableI /;
use base qw /  CXGN::Chado::Dbxref::EvidenceI   /;

=head2 new

 Usage: my $locus_dbxref_evidence = CXGN::Phenome::Locus::LocusDbxrefEvidence->new($dbh, $locus_dbxref_evidence_id);
 Desc:
 Ret:    
 Args: $dbh, $locus_dbxref_evidence_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the locus_dbxref_evidence_id of the LocusDbxrefEvidence object 
    
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

    my $evidence_query = $self->get_dbh()->prepare("SELECT  locus_dbxref_id, relationship_type_id, evidence_code_id, evidence_description_id, evidence_with, reference_id, sp_person_id, updated_by, create_date, modified_date, obsolete FROM phenome.locus_dbxref_evidence WHERE locus_dbxref_evidence_id=?");

    my $locus_dbxref_evidence_id=$self->get_object_dbxref_evidence_id();
         	   
    $evidence_query->execute($locus_dbxref_evidence_id);
    
    my ($locus_dbxref_id, $relationship_type_id, $evidence_code_id, $evidence_description_id, $evidence_with, $reference_id, $sp_person_id, $updated_by, $create_date, $modified_date, $obsolete)=$evidence_query->fetchrow_array();
    $self->set_object_dbxref_id($locus_dbxref_id);
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
    
    my $locus_dbxref_evidence_id=$self->get_object_dbxref_evidence_id()  || $self->evidence_exists();
    
    if (!$locus_dbxref_evidence_id) {
	$self->d("about to store a new locus_dbxref_evidence\n...");
	my $query = "INSERT INTO phenome.locus_dbxref_evidence (locus_dbxref_id, relationship_type_id, evidence_code_id, evidence_description_id, evidence_with, reference_id, sp_person_id) VALUES(?,?,?,?,?,?,?)";
	my $sth= $self->get_dbh()->prepare($query);
	
	$sth->execute($self->get_object_dbxref_id(), $self->get_relationship_type_id(), $self->get_evidence_code_id(),$self->get_evidence_description_id(), $self->get_evidence_with(), $self->get_reference_id(), $self->get_sp_person_id() );
	
	$locus_dbxref_evidence_id=  $self->get_dbh()->last_insert_id("locus_dbxref_evidence", "phenome");
	$self->set_object_dbxref_evidence_id($locus_dbxref_evidence_id);
	
    }elsif ($locus_dbxref_evidence_id ) {
	$self->d( "about to update locus_dbxref_evidence...\n" );
	my $query = "UPDATE phenome.locus_dbxref_evidence SET relationship_type_id=?, evidence_code_id=?, evidence_description_id=?, evidence_with=?, reference_id=?,  updated_by=?, obsolete='f', modified_date = now() WHERE locus_dbxref_evidence_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_relationship_type_id(), $self->get_evidence_code_id(),$self->get_evidence_description_id(), $self->get_evidence_with(), $self->get_reference_id(), $self->get_updated_by(), $locus_dbxref_evidence_id);
    }
    return $locus_dbxref_evidence_id;
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
 Desc:  sets to obsolete a locus_dbxref_evidence  
 Ret: nothing
 Args: none
 Side Effects: calls $self->store_history() 
 Example:

=cut

sub obsolete {

    my $self = shift;
    if ($self->get_object_dbxref_evidence_id()) { 
	
	my $query = "UPDATE phenome.locus_dbxref_evidence SET obsolete='t', modified_date=now(), updated_by=?
                  WHERE locus_dbxref_evidence_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_updated_by(), $self->get_object_dbxref_evidence_id());
	$self->store_history();
    }else { 
	print STDERR  "trying to delete a locus_dbxref_evidence that has not yet been stored to db.\n";
    }    
   
}		     

=head2 unobsolete

 Usage: $self->unobsolete()
 Desc:  unobsolete a locus_dbxref_evidence  
 Ret: nothing
 Args: none
 Side Effects: 
 Example:

=cut

sub unobsolete {

    my $self = shift;
    if ($self->get_object_dbxref_evidence_id()) { 
	my $query = "UPDATE phenome.locus_dbxref_evidence SET obsolete='f', modified_date=now()
                  WHERE locus_dbxref_evidence_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_object_dbxref_evidence_id());

    }else { 
	print STDERR  "trying to unobsolete a locus_dbxref_evidence that has not yet been stored to db.\n";
    }    
}		     


=head2 store_history

 Usage: $self->store_history() . call this function before deleting or updating 
 Desc:  'moves' the record to the locus_dbxref_evidence table
               this is important for allowing future updates of the locus_dbxref_evidence table
               is cases of a locus_dbxref being obsoleted and then being un-obsoleted with a new
               set of evidence codes and references. The old evidence codes will be kept in the history table
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub store_history {
    my $self=shift;
    if ($self->get_object_dbxref_evidence_id()) { 
	print STDERR "LocusDbxrefEvidence.pm **** store_history()\n\n";
	my $history_query= "INSERT INTO phenome.locus_dbxref_evidence_history
                            (locus_dbxref_evidence_id, locus_dbxref_id, relationship_type, evidence_code, evidence_description, evidence_with, reference_id, sp_person_id, updated_by,  modified_date, obsolete) 
                            VALUES (?,?,?,?,?,?,?,?,?,?,?) ";
	my $history_sth=$self->get_dbh()->prepare($history_query);
	$history_sth->execute($self->get_object_dbxref_evidence_id(), $self->get_object_dbxref_id(), $self->get_relationship_type_id(), $self->get_evidence_code_id, $self->get_evidence_description_id(), $self->get_evidence_with(), $self->get_reference_id(), $self->get_sp_person_id, $self->get_updated_by(), $self->get_modification_date(),$self->get_obsolete());
	my $id= $self->get_dbh()->last_insert_id("locus_dbxref_evidence_history", "phenome");
	print STDERR "*!*!locus_dbxref_evidence_history_id: $id***\n";
    }else { 
	print STDERR  "trying to store history of a locus_dbxref_evidence that has not yet been stored to db.\n";
    }    
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
    my $query = "SELECT locus_dbxref_evidence_id FROM phenome.locus_dbxref_evidence
                 WHERE relationship_type_id=?
                 AND evidence_code_id=?
                 AND locus_dbxref_id=?";
    my $sth=$self->get_dbh()->prepare( $query );
    print STDERR $self->get_relationship_type_id() . "," . $self->get_evidence_code_id() . "," . $self->get_object_dbxref_id() ."\n\n";
    $sth->execute( $self->get_relationship_type_id(), $self->get_evidence_code_id(), $self->get_object_dbxref_id() );
    my ($id) = $sth->fetchrow_array();
    return $id || undef;
}

=head2 get_locus_dbxref

 Usage: $self->get_locus_dbxref()
 Desc:  get the LocusDbxref object for this evidence 
 Ret:   a LocusDbxref object
 Args:  none
 Side Effects: none
 Example:

=cut

sub get_locus_dbxref {
    my $self=shift;
    return CXGN::Phenome::LocusDbxref->new($self->get_dbh(), $self->get_object_dbxref_id());
}

=head2 get_object_dbxref

 Usage:
 Desc: An alisas for get_locus_dbxref. Overriding a function in Chado::Dbxref::EvidenceI
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_object_dbxref {
    my $self=shift;
    return $self->get_locus_dbxref();
}



=head2 Accessors available

 locus_dbxref_evidence_id (DEPRECATED. replaced by get_object_dbxref_evidence_id)
 locus_dbxref_id  (DePRECATED . replaced by get_object_dbxref_id


The following acessors live in CXGN::Chado::Dbxref::EvidenceI    
 object_dbxref_evidence_id
 relationship_type_id
 evidence_code_id
 evidence_description_id
 evidence_description_id
 evidence_with
 reference_id

=cut

sub get_locus_dbxref_evidence_id {
    my $self=shift;
    #return $self->{locus_dbxref_evidence_id};
    warn "DEPRECATED. get_locus_dbxref_evidence_id has been replaced by get_object_dbxref_evidence_id";
    return $self->get_object_dbxref_evidence_id();
}

sub set_locus_dbxref_evidence_id {
  my $self=shift;
  #$self->{locus_dbxref_evidence_id}=shift;
  warn "DEPRECATED. get_locus_dbxref_evidence_id has been replaced by get_object_dbxref_evidence_id";
  $self->{object_dbxref_evidence_id}=shift;
}



sub get_locus_dbxref_id {
  my $self=shift;
  #return $self->{locus_dbxref_id};
  warn "DEPRECATED. get_locus_dbxref_id has been replaced by get_object_dbxref_id";
  return $self->get_object_dbxref_id();
}

sub set_locus_dbxref_id {
  my $self=shift;
  #$self->{locus_dbxref_id}=shift;
  warn "DEPRECATED. set_locus_dbxref_id has been replaced by set_object_dbxref_id";
  $self->{object_dbxref_id}=shift;
}

sub get_relationship_type_id {
  my $self=shift;
  return $self->{relationship_type_id};

}

sub set_relationship_type_id {
  my $self=shift;
  $self->{relationship_type_id}=shift;
}

sub get_evidence_code_id {
  my $self=shift;
  return $self->{evidence_code_id};

}

sub set_evidence_code_id {
  my $self=shift;
  $self->{evidence_code_id}=shift;
}

sub get_evidence_description_id {
  my $self=shift;
  return $self->{evidence_description_id};

}

sub set_evidence_description_id {
  my $self=shift;
  $self->{evidence_description_id}=shift;
}


sub get_evidence_with {
  my $self=shift;
  return $self->{evidence_with};

}

sub set_evidence_with {
  my $self=shift;
  $self->{evidence_with}=shift;
}

sub get_reference_id {
  my $self=shift;
  return $self->{reference_id};

}

sub set_reference_id {
  my $self=shift;
  $self->{reference_id}=shift;
}

=head2 get_cvterm

 Usage: $self->get_cvterm($dbxref_id)
 Desc:  get the cvterm name. Useful for finding the cvterm for each of the 
        evidence object details, which all are foreign keys to the public.dbxref table
        (relationship_type_id, evidence_code_id, reference_id, evidence_with, evidence_description_id) 
 Ret:   a cvterm_name string
 Args:  dbxref_id
 Side Effects: removes underscores from cvterm_name string
 Example:

=cut

sub get_cvterm {
    my $self=shift;
    my $dbxref_id=shift;
    my $dbxref_obj=CXGN::Chado::Dbxref->new($self->get_dbh(), $dbxref_id);
    #my $cvterm_obj=CXGN::Chado::Cvterm->new($self->get_dbh(), $cvterm_id);
    my $cvterm_name=$dbxref_obj->get_cvterm_name();
    if ($cvterm_name) {$cvterm_name=~s /_/ / ; }

    return $cvterm_name;
}


##########
return 1;#
##########
