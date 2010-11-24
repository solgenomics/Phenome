=head1 NAME

CXGN::Phenome::Germplasm - a class that deals with germplasms of individual accessions (plants from different mapping/mutant/introgression populations)

=head1 DESCRIPTION

This class inherits from CXGN::Page::Form::UserModifiable and can therefore be used to implement user-modifiable pages easily. It also inherits from CXGN::Phenome::Main, which deals with the database connection.

=head1 AUTHOR(S)

Naama Menda (nm249@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

use strict;

use CXGN::DB::Connection;

package CXGN::Phenome::Germplasm;
use base qw/ CXGN::Phenome::Main CXGN::DB::ModifiableI /;


=head2 new
  Synopsis:	my $g = CXGN::Phenome::Germplasm->new($dbh, $germplasm_id)
  Arguments:	a database handle and a germplasm id
  Returns:	a germplasm object
  Side effects:	if $germplasm_id is omitted, an empty project is created. 
                if an illegal $germplasm_id is supplied, undef is returned.
  Description:	

=cut

sub new {

    my $class = shift;
    my $self= $class->SUPER::new(@_);
    my $dbh = shift;
    my $germplasm_id = shift;
    
    if (!$dbh->isa("DBI")) { 
	die "First argument to CXGN::Phenome::Germplasm constructor needs to be a database handle.";
    }
    if ($germplasm_id) { 
	$self->set_germplasm_id($germplasm_id);
	$germplasm_id = $self->fetch();
	if (!$germplasm_id) { return undef; }
    }
    return $self;
    
}

sub fetch {
    my $self=shift;
    my $query= "SELECT germplasm_id, germplasm_type, individual_id, description, dbxref_id, sp_person_id,create_date, modified_date FROM germplasm where germplasm_id=? and obsolete= 'f'";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_germplasm_id());
    my ($germplasm_id, $germplasm_type, $individual_id, $description, $dbxref_id, $sp_person_id, $create_date, $modified_date)= $sth->fetchrow_array();

    $self->set_germplasm_id($germplasm_id);
    $self->set_germplasm_type($germplasm_type);
    $self->set_individual_id($individual_id);
    $self->set_description($description);
    $self->set_dbxref_id($dbxref_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modified_date($modified_date);
    
    return $germplasm_id;
}


=head2 function store

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub store {
    my $self = shift;
    if ($self->get_germplasm_id()) { 
	my $query = "UPDATE phenome.germplasm SET
                       germplasm_type = ?,
                       description = ?,
                       sp_person_id=?,
                       modified_date = now()
                     WHERE
                       germplasm_id = ?
                     ";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_germplasm_type(), $self->get_description(), $self->get_sp_person_id(), $self->get_germplasm_id());
    }
    else {
	my $query = "INSERT INTO phenome.germplasm
                      (germplasm_type, description, sp_person_id, modified_date)
                     VALUES
                      (?, ?, ?, now()) RETURNING germplasm_id";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_germplasm_type(), $self->get_description(),
                      $self->get_sp_person_id());
        my ($id) = $sth->fetchrow_array();
        $self->set_germplasm_id($id);
    }
    return $self->get_germplasm_id();
}



=head2 get_germplasm_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_germplasm_id {
  my $self=shift;
  return $self->{germplasm_id};

}

=head2 set_germplasm_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_germplasm_id {
  my $self=shift;
  $self->{germplasm_id}=shift;
}

=head2 get_germplasm_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_germplasm_type {
  my $self=shift;
  return $self->{germplasm_type};

}

=head2 set_germplasm_type

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_germplasm_type {
  my $self=shift;
  $self->{germplasm_type}=shift;
}


=head2 get_individual_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_individual_id {
  my $self=shift;
  return $self->{individual_id};

}

=head2 set_individual_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_individual_id {
  my $self=shift;
  $self->{individual_id}=shift;
}

=head2 get_description

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_description {
  my $self=shift;
  return $self->{description};

}

=head2 set_description

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_description {
  my $self=shift;
  $self->{description}=shift;
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



return 1;


