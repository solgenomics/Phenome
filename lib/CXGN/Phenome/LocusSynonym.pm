

=head1 NAME

CXGN::Phenome::LocusSynonym 
display synonyms of a locus 

=head1 SYNOPSIS

=head1 AUTHOR

Naama

=cut
use CXGN::DB::Connection;


package CXGN::Phenome::LocusSynonym;
use CXGN::Phenome::Locus;

use base qw/ CXGN::DB::ModifiableI /;

=head2 new

 Usage: my $gene = CXGN::Phenome::LocusSynonym->new($dbh, $locus_synonym_id);
 Desc:
 Ret:    
 Args: $dbh, $locus_synonym_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the locus_synonym_id of the locus_synonym object 
        
    my $args = {};  
    
    my $self=$class->SUPER::new($dbh);   

    $self->set_locus_alias_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;
    
    my $locus_synonym_query = "SELECT  locus_alias.locus_id, locus_alias.alias, locus_alias.sp_person_id, locus_alias.create_date, locus_alias.modified_date, locus_alias.obsolete, locus_alias.preferred, locus.locus_name, sgn.common_name.common_name 
FROM phenome.locus_alias 
JOIN phenome.locus USING(locus_id) JOIN sgn.common_name USING (common_name_id)
 WHERE locus_alias_id=? and locus_alias.obsolete='f'";
    my $sth=$self->get_dbh()->prepare($locus_synonym_query);
    
    $sth->execute( $self->get_locus_alias_id());
    
    my ($locus_id, $alias, $sp_person_id, $create_date, $modified_date, $obsolete, $preferred, $locus_name, $common_name)=$sth->fetchrow_array();
    $self->set_locus_id($locus_id);
    $self->set_locus_alias($alias);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_obsolete($obsolete);
    $self->set_preferred($preferred);
    $self->set_locus_name($locus_name);
    $self->set_common_name($common_name);
    
}

sub store {
    my $self= shift;
    my $id = $self->get_locus_alias_id();
    my $obsolete;

    ($id, $obsolete)= exists_locus_synonym_named($self->get_dbh(), $self->get_locus_alias(), $self->get_locus_id()) if !$id;
    
    if ($id) {
	my $query = "UPDATE phenome.locus_alias SET 
                 obsolete = ?,
                 alias= ?,
                 preferred =?,
                 sp_person_id=?,
                 modified_date =now()
                WHERE locus_alias_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_obsolete(), $self->get_locus_alias(), $self->get_preferred(), $self->get_sp_person_id(),$id);

    }else {
	my $query = "INSERT INTO phenome.locus_alias (locus_id, alias, sp_person_id) VALUES(?,?,?) RETURNING locus_alias_id";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_locus_id, $self->get_locus_alias, $self->get_sp_person_id);
	($id)= $sth->fetchrow_array;
	$self->set_locus_alias_id($id);
    }
    return $id;
}


sub delete { 
    my $self = shift;
    if ($self->get_locus_alias_id()) { 

	my $query = "DELETE FROM phenome.locus_alias WHERE locus_alias_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_locus_alias_id());
	
    }else { 
	print STDERR  "trying to delete a locus synonym that has not yet been stored to db.\n";
    }    
}

=head2 exists_locus_synonym_named

 Usage: my ($existing_id, $obsolete) = CXGN::Phenome::LocusSynonym::exists_locus_synonym_named($dbh, $locus_alias, $locus_id);
 Desc:  Class function . find out if an alias exists for a locus  
 Ret:   database id and obsolete status, or undef
 Args:  dbh, alias, locus_id
 Side Effects: none
 Example:

=cut

sub exists_locus_synonym_named {
    my $dbh = shift;
    my $alias = shift;
    my $locus_id=shift;
    my $query = "SELECT locus_alias_id, obsolete 
                   FROM phenome.locus_alias
                  WHERE alias ILIKE ? and locus_id = ?";
    my $sth = $dbh->prepare($query);
    $sth->execute($alias, $locus_id);
    if (my ($id, $obsolete)=$sth->fetchrow_array()) { 
	return $id, $obsolete;
    }
    else { 
	return 0;
    }
}
		 
=head2 Available accessors (get/set):

 locus_alias_id
 locus_id 
 locus_alias
 preferred
 common_name
 locus_name

Accessors available from ModifiableI:
 obsolete
 sp_person_id
 create_date
 modification_date 

=cut


sub get_locus_id {
  my $self = shift;
  return $self->{locus_id}; 
}

sub set_locus_id {
  my $self = shift;
  $self->{locus_id} = shift;
}

sub get_locus_alias_id {
  my $self=shift;
  return $self->{locus_alias_id};

}

sub set_locus_alias_id {
  my $self=shift;
  $self->{locus_alias_id}=shift;
}

sub get_locus_alias {
  my $self=shift;
  return $self->{locus_alias};

}

sub set_locus_alias {
  my $self=shift;
  $self->{locus_alias}=shift;
}


sub get_preferred {
  my $self = shift;
  return $self->{preferred}; 
}

sub set_preferred {
  my $self = shift;
  $self->{preferred} = shift;
}

sub get_common_name {
  my $self = shift;
  return $self->{common_name}; 
}

sub set_common_name {
  my $self = shift;
  $self->{common_name} = shift;
}

sub get_locus_name {
  my $self = shift;
  return $self->{locus_name}; 
}

sub set_locus_name {
  my $self = shift;
  $self->{locus_name} = shift;
}


###
1;#do not remove
###



