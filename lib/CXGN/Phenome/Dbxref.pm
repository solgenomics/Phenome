=head1 NAME

CXGN::Phenome::Dbxref 
display dbxrefs of a locus 

=head1 SYNOPSIS

=head1 AUTHOR

Naama

=cut
use CXGN::DB::Connection;
use CXGN::Phenome::Locus; 


package CXGN::Phenome::Dbxref;

use base qw( CXGN::Phenome::Main );


=head2 new

 Usage: my $gene = CXGN::Phenome::Dbxref->new($dbxref_id, $dbh);
 Desc:
 Ret:    
 Args: $dbxref_id
 Side Effects:
 Example:

=cut


sub new {
    my $class = shift;
    my $id= shift; # the dbxref_id of the dbxref object 
    my $dbh= shift;
    
    my $args = {};  
    my $self = bless $args, $class;

    my $self=$class->SUPER::new($dbh);   

    $self->set_dbxref_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;

    my $dbxref_query = $self->get_dbh()->prepare("SELECT  dbxref_type_id, dbxref_key  FROM phenome.dbxref  WHERE dbxref_id=? and obsolete='f'");

    my $dbxref_id=$self->get_dbxref_id();
         	   
    $dbxref_query->execute( $dbxref_id );

 
    ($self->{dbxref_type_id},$self->{dbxref_key})=$dbxref_query->fetchrow_array();

    
}

sub delete { 
    my $self = shift;
    if ($self->get_dbxref_id()) { 
	my $query = "UPDATE phenome.dbxref SET obsolete='t'
                  WHERE dbxref_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_dbxref_id());
	
    }else { 
	print STDERR  "trying to delete a dbxref that has not yet been stored to db.\n";
    }    
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

=head2 get_dbxref_type_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_type_id {
  my $self=shift;
  return $self->{dbxref_type_id};

}

=head2 set_dbxref_type_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_type_id {
  my $self=shift;
  $self->{dbxref_type_id}=shift;
}

=head2 get_dbxref_key

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_key {
  my $self=shift;
  return $self->{dbxref_key};

}

=head2 set_dbxref_key

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_key {
  my $self=shift;
  $self->{dbxref_key}=shift;
}





###
1;#do not remove
###
