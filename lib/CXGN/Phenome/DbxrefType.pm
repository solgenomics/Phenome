
use strict;

package CXGN::Phenome::DbxrefType;

use base qw / CXGN::Phenome::Main /;

# implements an object for the following database table:
#
#          Column         |          Type          |            Modifiers 
#  dbxref_type_id         | integer                | not null default nextval (...)
#  dbxref_type_name       | character varying(32)  | 
#  dbxref_type_definition | character varying(255) | 
#  dbxref_type_url        | character varying(255) | 


=head2 new

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self= $class->SUPER::new($dbh);

    if ($id) { 
	$self->set_dbxref_type_id($id);
	$self->fetch();
    }
    return $self;
}

=head2 fetch

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub fetch {
    my $self = shift;
    my $query = "SELECT dbxref_type_id, dbxref_type_name, dbxref_type_definition, dbxref_type_url
                   FROM phenome.dbxref_type 
                  WHERE dbxref_type_id=?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_dbxref_type_id());
    my ($dbxref_type_id, $dbxref_type_name, $dbxref_type_definition, $dbxref_type_url) = 
	$sth->fetchrow_array();
    
    $self->set_dbxref_type_id($dbxref_type_id);
    $self->set_dbxref_type_url($dbxref_type_url);
    $self->set_dbxref_type_name($dbxref_type_name);
    $self->set_dbxref_type_definition($dbxref_type_definition);
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

=head2 get_dbxref_type_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_type_name {
  my $self=shift;
  return $self->{dbxref_type_name};

}

=head2 set_dbxref_type_name

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_type_name {
  my $self=shift;
  $self->{dbxref_type_name}=shift;
}

=head2 get_dbxref_type_definition

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_type_definition {
  my $self=shift;
  return $self->{dbxref_type_definition};

}

=head2 set_dbxref_type_definition

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_type_definition {
  my $self=shift;
  $self->{dbxref_type_definition}=shift;
}

=head2 get_dbxref_type_url

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_dbxref_type_url {
  my $self=shift;
  return $self->{dbxref_type_url};

}

=head2 set_dbxref_type_url

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_dbxref_type_url {
  my $self=shift;
  $self->{dbxref_type_url}=shift;
}


=head2 get_all_dbxref_types

 Usage:        
 Desc:
 Ret:          (dbxref_type_name_ref_list, dbxref_type_id_ref_list)
 Args:         a database handle
 Side Effects:
 Example:

=cut

sub get_all_dbxref_types {
    my $dbh = shift;
    my $query = "SELECT dbxref_type_name, dbxref_type_id FROM phenome.dbxref_type";
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my @namespace_names = ();
    my @namespace_ids = ();
    while (my ($name, $id) = $sth->fetchrow_array()) { 
	push @namespace_names, $name;
	push @namespace_ids , $id;
    }
    return (\@namespace_names, \@namespace_ids);
}


return 1;
