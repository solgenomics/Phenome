

=head1 NAME

CXGN::Phenome::AlleleDbxref 
display dbxrefs associated with an allele 

=head1 SYNOPSIS

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut
use CXGN::DB::Connection;
use CXGN::Phenome::Allele; 

package CXGN::Phenome::AlleleDbxref;

use base qw / CXGN::Phenome::Main CXGN::Phenome::Allele CXGN::DB::ModifiableI /;


=head2 new

 Usage: my $allele_dbxref = CXGN::Phenome::AlleleDbxref->new($dbh, $allele_dbxref_id);
 Desc:
 Ret:    
 Args: $dbh, $allele_dbxref_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the allele_dbxref_id of the AlleleDbxref object 
    
    my $args = {};  
 
    my $self=$class->SUPER::new($dbh);   

    $self->set_allele_dbxref_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;

    my $allele_dbxref_query = $self->get_dbh()->prepare("SELECT  allele_id, dbxref_id, sp_person_id, create_date, modified_date, obsolete FROM phenome.allele_dbxref WHERE allele_dbxref_id=?");

    my $allele_dbxref_id=$self->get_allele_dbxref_id();
         	   
    $allele_dbxref_query->execute($allele_dbxref_id);
    
    my ($allele_id, $dbxref_id, $sp_person_id, $create_date, $modified_date, $obsolete)=$allele_dbxref_query->fetchrow_array();
    $self->set_allele_id($allele_id);
    $self->set_dbxref_id($dbxref_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_obsolete($obsolete);
}

=head2 get_allele_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub store {
    my $self= shift;
    my $obsolete= $self->get_obsolete();
    my $allele_dbxref_id=$self->get_allele_dbxref_id();
    print STDERR "obsolete= $obsolete, id= $allele_dbxref_id\n";
    if ($obsolete eq 'f') {
	my $query = "INSERT INTO phenome.allele_dbxref (allele_id, dbxref_id, sp_person_id) VALUES(?,?,?)";
	my $sth= $self->get_dbh()->prepare($query);
	
	$sth->execute($self->get_allele_id, $self->get_dbxref_id, $self->get_sp_person_id);
		
    }else {
	my $query = "UPDATE phenome.allele_dbxref SET obsolete='f', sp_person_id=? WHERE allele_dbxref_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_sp_person_id, $allele_dbxref_id);
    }
    #return $allele_dbxref_id; 
}


=head2 delete

 Usage: $self->delete()
 Desc:  sets to obsolete an allele_dbxref  
 Ret: nothing
 Args: none
 Side Effects:
 Example:

=cut

sub delete {

    my $self = shift;
    if ($self->get_allele_dbxref_id()) { 
	my $query = "UPDATE phenome.allele_dbxref SET obsolete='t', modified_date=now()
                  WHERE allele_dbxref_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_allele_dbxref_id());
    }else { 
	print STDERR  "trying to delete an allele_dbxref that has not yet been stored to db.\n";
    }    
}		     




=head2 get_allele_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_allele_dbxref_id {
  my $self=shift;
  return $self->{allele_dbxref_id};

}

=head2 set_allele_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_allele_dbxref_id {
  my $self=shift;
  $self->{allele_dbxref_id}=shift;
}


=head2 get_allele_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_allele_id {
  my $self=shift;
  return $self->{allele_id};

}

=head2 set_allele_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_allele_id {
  my $self=shift;
  $self->{allele_id}=shift;
}



=head2 get_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_id {
  my $self=shift;
  return $self->{dbxref_id};

}

=head2 set_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_id {
  my $self=shift;
  $self->{dbxref_id}=shift;
}




=head2 get_allele_publications

 Usage: my $allele->get_allele_publications()
 Desc:  get all the publications associated with an allele
 Ret:   an array of publication objects
 Args:  none
 Side Effects:
 Example:

=cut

sub get_allele_publications {
    my $self=shift;
    my $query = $self->get_dbh()->prepare("SELECT pub_id FROM pub_dbxref 
                                           JOIN dbxref USING (dbxref_id)
                                           JOIN phenome.allele_dbxref USING (dbxref_id)
                                           WHERE allele_id = ?");
    $query->execute($self->get_allele_id());
    my $publication;
    my @publications;
    while (my ($pub_id) = $query->fetchrow_array()) { 
	$publication = CXGN::Chado::Publication->new($self->get_dbh(), $pub_id);
	push @publications, $publication;
    }
    return @publications;

}




###
1;#do not remove
###



