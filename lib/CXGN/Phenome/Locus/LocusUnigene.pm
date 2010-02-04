

=head1 NAME

CXGN::Phenome::LocusUnigene 


=head1 SYNOPSIS

Class for accessing  unigenes associated with a locus 

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut
use CXGN::DB::Connection;
use CXGN::Phenome::Locus; 
use CXGN::DB::Object;

package CXGN::Phenome::Locus::LocusUnigene;

use base qw / CXGN::DB::ModifiableI /;


=head2 new

 Usage: my $locus_unigene = CXGN::Phenome::Locus::LocusUnigene->new($dbh, $locus_unigene_id);
 Desc:
 Ret:    
 Args: $dbh, $locus_unigene_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # 
    my $args = {};  

    my $self=$class->SUPER::new($dbh);   

    $self->set_locus_unigene_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;
;
    my $query = $self->get_dbh()->prepare("SELECT  locus_id, unigene_id, obsolete, sp_person_id, create_date, modified_date FROM phenome.locus_unigene WHERE locus_unigene_id=?");

    my $locus_u_id=$self->get_locus_unigene_id();
         	   
    $query->execute($locus_u_id);
    
    my ($locus_id, $unigene_id, $obsolete, $sp_person_id, $create_date, $modified_date)=$query->fetchrow_array();
    $self->set_locus_id($locus_id);
    $self->set_unigene_id($unigene_id);
    $self->set_obsolete($obsolete);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
}


sub store {
    my $self=shift;
    my $id=$self->get_locus_unigene_id();
    if (!$id) {
	if ( $self->exists_in_database() ) {
	    warn "Locus " . $self->get_locus_id() . " is already associated with unigene " . $self->get_unigene_id() . " Skipping... \n";
	    return;
	}
	my $query= $self->get_dbh()->prepare("INSERT INTO phenome.locus_unigene (locus_id, unigene_id, sp_person_id)
                                          VALUES (?,?,?)");
	$query->execute($self->get_locus_id, $self->get_unigene_id(), $self->get_sp_person_id());
	
	$id= $self->get_currval("phenome.locus_unigene_locus_unigene_id_seq");
	$self->set_locus_unigene_id($id);
    }else { 
	my $query  = "UPDATE phenome.locus_unigene SET 
                      sp_person_id=?,
                      obsolete=?,
                      modified_date=now()
		      WHERE locus_unigene_id= ?"; 
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_sp_person_id(), $self->get_obsolete(), $id);
    }
    return $id;
}



=head2 accessors get_locus_unigene_id, set_locus_unigene_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_locus_unigene_id {
  my $self = shift;
  return $self->{locus_unigene_id}; 
}

sub set_locus_unigene_id {
  my $self = shift;
  $self->{locus_unigene_id} = shift;
}


=head2 accessors get_locus_id, set_locus_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_locus_id {
  my $self=shift;
  return $self->{locus_id};

}


sub set_locus_id {
  my $self=shift;
  $self->{locus_id}=shift;
}



=head2 accessors get_unigene_id, set_unigene_id

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_unigene_id {
  my $self = shift;
  return $self->{unigene_id}; 
}

sub set_unigene_id {
  my $self = shift;
  $self->{unigene_id} = shift;
}

=head2 exists_in_database

 Usage: $self->exists_in_database()
 Desc:  check if the locus is already associated with the unigene 
 Ret:   database_id 
 Args:  none
 Side Effects:
 Example:

=cut

sub exists_in_database {
    my $self=shift;
    my $query = "SELECT locus_unigene_id FROM phenome.locus_unigene
                 WHERE locus_id=? AND unigene_id =?";
    my $sth=$self->get_dbh()->prepare($query);
    $sth->execute($self->get_locus_id(), $self->get_unigene_id());
    my ($id) = $sth->fetchrow_array();
    return $id;
}



###
1;#do not remove
###



