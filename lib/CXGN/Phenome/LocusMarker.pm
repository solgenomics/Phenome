

=head1 NAME

CXGN::Phenome::LocusMarker 


=head1 SYNOPSIS

Class for accessing  markers associated with a locus 

=head1 AUTHOR

Naama Menda (nm249@cornell.edu)

=cut
use CXGN::DB::Connection;
use CXGN::Phenome::Locus; 
use CXGN::DB::Object;

package CXGN::Phenome::LocusMarker;

use base qw / CXGN::Phenome::Main CXGN::DB::ModifiableI /;


=head2 new

 Usage: my $locus_marker = CXGN::Phenome::LocusMarker->new($dbh, $locus_marker_id);
 Desc:
 Ret:    
 Args: $dbh, $locus_marker_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the locus_marker_id of the locus_marker object 
    
    my $args = {};  

    my $self=$class->SUPER::new($dbh);   

    $self->set_locus_marker_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;
;
    my $locus_marker_query = $self->get_dbh()->prepare("SELECT  locus_id, marker_id, obsolete, sp_person_id, create_date, modified_date FROM phenome.locus_marker WHERE locus_marker_id=?");

    my $locus_marker_id=$self->get_locus_marker_id();
         	   
    $locus_marker_query->execute($locus_marker_id);
    
    my ($locus_id, $marker_id, $obsolete, $sp_person_id, $create_date, $modified_date)=$locus_marker_query->fetchrow_array();
    $self->set_locus_id($locus_id);
    $self->set_marker_id($marker_id);
    $self->set_obsolete($obsolete);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
}


sub store {
    my $self=shift;
    my $locus_marker_id=$self->get_locus_marker_id();
    if (!$locus_marker_id) {
	my $query= $self->get_dbh()->prepare("INSERT INTO phenome.locus_marker (locus_id, marker_id, sp_person_id)
                                          VALUES (?,?,?)");
	$query->execute($self->get_locus_id, $self->get_marker_id(), $self->get_sp_person_id());
	
	$locus_marker_id= $self->get_currval("phenome.locus_marker_locus_marker_id_seq");
	$self->set_locus_marker_id($locus_marker_id);
    }else { 
	my $query  = "UPDATE phenome.locus_marker SET 
                      sp_person_id=?,
                      obsolete=?,
                      modified_date=now()
		      WHERE locus_marker_id= ?"; 
	my $sth=$self->get_dbh()->prepare($query);
	$sth->execute($self->get_sp_person_id(), $self->get_obsolete(), $locus_marker_id);
    }
    return $locus_marker_id;
}



=head2 accessors get_locus_marker_id, set_locus_marker_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_locus_marker_id {
  my $self=shift;
  return $self->{locus_marker_id};

}


sub set_locus_marker_id {
  my $self=shift;
  $self->{locus_marker_id}=shift;
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



=head2 accessors get_marker_id, set_marker_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_marker_id {
  my $self=shift;
  return $self->{marker_id};

}


sub set_marker_id {
  my $self=shift;
  $self->{marker_id}=shift;
}


###
1;#do not remove
###



