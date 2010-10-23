

=head1 NAME

CXGN::Phenome::IndividualDbxref 
display dbxrefs associated with an individual 

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut
use CXGN::DB::Connection;
use CXGN::Phenome::Individual::IndividualDbxrefEvidence;

package CXGN::Phenome::Individual::IndividualDbxref;

use base qw /  CXGN::Chado::Dbxref::DbxrefI  CXGN::Phenome::Individual /;


=head2 new

 Usage: my $individual_dbxref = CXGN::Phenome::Individual::IndividualDbxref->new($dbh, $individual_dbxref_id);
 Desc:
 Ret:    
 Args: $dbh, $individual_dbxref_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the individual_dbxref_id of the IndividualDbxref object 
    
    my $args = {};  

    my $self=$class->SUPER::new($dbh);   

    $self->set_object_dbxref_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;

    my $individual_dbxref_query = $self->get_dbh()->prepare("SELECT  individual_id, dbxref_id, sp_person_id, create_date, modified_date, obsolete FROM phenome.individual_dbxref WHERE individual_dbxref_id=?");

    my $individual_dbxref_id=$self->get_object_dbxref_id();
         	   
    $individual_dbxref_query->execute($individual_dbxref_id);
    
    my ($individual_id, $dbxref_id, $sp_person_id, $create_date, $modified_date, $obsolete)=$individual_dbxref_query->fetchrow_array();
    $self->set_individual_id($individual_id);
    $self->set_dbxref_id($dbxref_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_obsolete($obsolete);
}

sub store {
    my $self= shift;
    my $obsolete= $self->get_obsolete();
    my $individual_dbxref_id=$self->get_object_dbxref_id()  || object_dbxref_exists($self->get_dbh(), $self->get_individual_id(), $self->get_dbxref_id() );
    print STDERR "IndividualDbxref is storing entry for individual " .  $self->get_individual_id() . " dbxref_id = " . $self->get_dbxref_id() . "\n\n";
    if (!$individual_dbxref_id) {
	print STDERR "IndividualDbxref is storing a new entry...\n";
	my $query = "INSERT INTO phenome.individual_dbxref (individual_id, dbxref_id, sp_person_id) VALUES(?,?,?)";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_individual_id, $self->get_dbxref_id, $self->get_sp_person_id);
	
	$individual_dbxref_id=  $self->get_dbh()->last_insert_id("individual_dbxref", "phenome");
	$self->set_object_dbxref_id($individual_dbxref_id);
   
    }elsif ($obsolete eq 't' ) {
	my $query = "UPDATE phenome.individual_dbxref SET obsolete='f', sp_person_id=? , modified_date=now() 
            WHERE individual_dbxref_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_sp_person_id, $individual_dbxref_id);
    }else { print STDERR "individual_dbxref already stored!!\n\n";  }
    
    return $individual_dbxref_id; 
}


=head2 obsolete

 Usage: $self->obsolete()
 Desc:  sets to obsolete a individual_dbxref  
 Ret: nothing
 Args: none
 Side Effects: obsolete the evidence codes
               and stores the individual_dbxref_evidence entry in its history table.
               See IndividualDbxrefEvidence::store_history()
 Example:

=cut

sub obsolete {

    my $self = shift;
    if ($self->get_object_dbxref_id()) { 
	my $query = "UPDATE phenome.individual_dbxref SET obsolete='t', modified_date=now()
                  WHERE individual_dbxref_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_object_dbxref_id());
	#this stores the individual_dbxref_evidence entry in its history table, if the same term was ever unobsolete
	#the history helps keep track of the previous evidence codes that now have been updated.
	# obsolete all derived evidence codes and store_history();
	foreach ($self->get_object_dbxref_evidence()) { $_-> obsolete(); }
    }else { 
	print STDERR  "trying to obsolete a individual_dbxref that has not yet been stored to db.\n";
    }    
}		     


=head2 delete

 Usage: obsolete individual_dbxref (we do not delete entries from this table)
 Desc: synonym for $self->obsolete()
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub delete {
    my $self=shift;
    $self->obsolete();
}



=head2 unobsolete

 Usage: $self->unobsolete()
 Desc:  unobsolete individual_dbxref  
 Ret: nothing
 Args: none
 Side Effects: 
 Example:

=cut

sub unobsolete {

    my $self = shift;
    if ($self->get_object_dbxref_id()) { 
	my $query = "UPDATE phenome.individual_dbxref SET obsolete='f', modified_date=now()
                  WHERE individual_dbxref_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_object_dbxref_id());

    }else { 
	print STDERR  "trying to unobsolete an individual_dbxref that has not yet been stored to db.\n";
    }    
}		     



=head2 accessors in this class
    individual_dbxref_id
    dbxref_id

=cut


sub get_individual_dbxref_id {
  my $self=shift;
  warn "DEPRECATED. get_individual_dbxref_id has been replaced by set_object_dbxref_id";
  return $self->get_object_dbxref_id();

}

sub set_individual_dbxref_id {
  my $self=shift;
  warn "DEPRECATED. set_individual_dbxref_id has been replaced by set_object_dbxref_id";
  $self->{object_dbxref_id}=shift;
 # $self->{individual_dbxref_id}=shift;
}


=head2 accessors get_individual_id, set_individual_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_individual_id {
  my $self = shift;
  return $self->{individual_id}; 
}

sub set_individual_id {
  my $self = shift;
  $self->{individual_id} = shift;
}


=head2 get_individual_publications

 Usage: my $individual->get_individual_publications()
 Desc:  get all the publications associated with a individual
 Ret:   an array of publication objects
 Args:  none
 Side Effects:
 Example:

=cut

sub get_individual_publications {
    my $self=shift;
    my $query = $self->get_dbh()->prepare("SELECT pub_id FROM pub_dbxref 
                                           JOIN dbxref USING (dbxref_id)
                                           JOIN phenome.individual_dbxref USING (dbxref_id)
                                           WHERE individual_id = ?");
    $query->execute($self->get_individual_id());
    my $publication;
    my @publications;
    while (my ($pub_id) = $sth->fetchrow_array()) { 
	$publication = CXGN::Chado::Publication->new($self->get_dbh(), $pub_id);
	push @publications, $publication;
    }
    return @publications;
}

=head2 get_object_dbxref_evidence

 Usage: $individual_dbxref->get_object_dbxref_evidence()
 Desc:  get all the evidence data associated with a individual dbxref (ontology term)
 Ret:   a list of L<CXGN::Phenome::Individual::IndividualDbxrefEvidence> objects
 Args:  none
 Side Effects:
 Example:

=cut

sub get_object_dbxref_evidence {
    my $self=shift;
    my $query = $self->get_dbh()->prepare("SELECT individual_dbxref_evidence_id FROM phenome.individual_dbxref_evidence 
                                           WHERE individual_dbxref_id = ?");
    my $individual_dbxref_id= $self->get_object_dbxref_id();
    
    $query->execute($self->get_object_dbxref_id());
    my $evidence;
    my @evidences;
    while (my ($evidence_id) = $query->fetchrow_array() ) {
	$evidence = CXGN::Phenome::Individual::IndividualDbxrefEvidence->new($self->get_dbh(), $evidence_id);
	push @evidences, $evidence;
    }
    return @evidences;
}

=head2 get_individual_dbxref_evidence

 Usage: DEPRECATED
 Desc: a synonym for get_object_dbxref_evidence. Need to have this alias for working with DbxrefI
 Ret:
 Args:
 Side Effects:
 Example:

=cut


sub get_individual_dbxref_evidence {
    my $self=shift;
    warn "DEPRECATED. replaced by get_object_dbxref_evidence()! .";
    return $self->get_object_dbxref_evidence();
    
}

=head2 object_dbxref_exists

 Usage: my $individual_dbxref_id= CXGN::Phenome::Individual::IndividualDbxref::object_dbxref_exists($dbh, $individual_id, $dbxref_id)
 Desc:  check if individual_id is associated with $dbxref_id  
  Ret: $individual_dbxref_id 
 Args:  $dbh, $individual_id, $dbxref_id
 Side Effects:
 Example:

=cut

sub object_dbxref_exists {
    my ($dbh, $individual_id, $dbxref_id)=@_;
    my $query = "SELECT individual_dbxref_id from phenome.individual_dbxref 
                 WHERE individual_id= ? and dbxref_id = ? ";
    my $sth=$dbh->prepare($query);
    $sth->execute($individual_id, $dbxref_id);
    my ($individual_dbxref_id) = $sth->fetchrow_array();
    print STDERR "*!*!individual_dbxref_exists\n individual_id:$individual_id, dbxref_id: $dbxref_id, individual_dbxref_id: $individual_dbxref_id ! \n\n" if $individual_dbxref_id;
    return $individual_dbxref_id;
}

=head2 individual_dbxref_exists

 Usage: DEPRECATED
 Desc:  alias for object_dbxref_exists
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub individual_dbxref_exists {
    #my @_=shift;
    warn "DEPRECATED. Replaced by object_dbxref_exists() !. ";
    return object_dbxref_exists(@_);
}


	
=head2 add_individual_dbxref_evidence

 Usage:        DEPRECATED .
 Desc:         replaced by add_object_dbxref_evidence
 Ret:          nothing
 Args:        
 Side Effects:  
 Example:

=cut

sub add_individual_dbxref_evidence {
    my $self=shift;
    my $evidence=shift; 
    $self->add_object_dbxref_evidence($evidence);
}


###
1;#do not remove
###



