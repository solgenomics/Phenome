

=head1 NAME

CXGN::Phenome::AlleleSynonym 
display synonyms of an allele  

=head1 SYNOPSIS

=head1 AUTHOR

Naama

=cut
use CXGN::DB::Connection;
use CXGN::Phenome::Allele;

package CXGN::Phenome::AlleleSynonym;

use base qw/ CXGN::Phenome::Main  CXGN::Phenome::Allele CXGN::DB::ModifiableI/;

=head2 new

 Usage: my $gene = CXGN::Phenome::AlleleSynonym->new($dbh, $allele_synonym_id);
 Desc:
 Ret:    
 Args: $allele_synonym_id, $dbh
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the allele_synonym_id of the allele_synonym object 
    
    my $args = {};  

    my $self=$class->SUPER::new($dbh);   

    $self->set_allele_alias_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;
;
    my $allele_synonym_query = $self->get_dbh()->prepare("SELECT  allele_id, alias, sp_person_id, create_date, modified_date FROM phenome.allele_alias WHERE allele_alias_id=? and obsolete='f'");

        	   
    $allele_synonym_query->execute( $self->get_allele_alias_id());

    my ($allele_id, $alias, $sp_person_id, $create_date, $modified_date)=$allele_synonym_query->fetchrow_array();
    $self->set_allele_id($allele_id);
    $self->set_allele_alias($alias);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    
}

sub store {
    my $self= shift;
    if ($self->get_allele_alias_id()) {
	my $query = "UPDATE phenome.allele_alias SET
                         alias=?,
                         sp_person_id= ?,
                         modified_date = now()
                         where allele_alias_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_allele_alias, $self->get_sp_person_id);
	return $self->get_allele_alias_id();
    }
    else {
	my $query = "INSERT INTO phenome.allele_alias (allele_id, alias, sp_person_id) VALUES(?,?,?)";
	my $sth= $self->get_dbh()->prepare($query);

	
	$sth->execute($self->get_allele_id, $self->get_allele_alias, $self->get_sp_person_id);
	#return $self->get_dbh()->last_insert_id("allele_alias");
    }
    return $self->get_allele_alias_id();
}                

sub delete { 
    my $self = shift;
    if ($self->get_allele_alias_id()) { 
	my $query = "UPDATE phenome.allele_alias SET obsolete='t'
                  WHERE allele_alias_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_allele_alias_id());
	
    }else { 
	print STDERR  "trying to delete a allele synonym that has not yet been stored to db.\n";
    }    
}


sub exists_allele_synonym_named {
    my $dbh = shift;
    my $alias = shift;
    my $allele_id=shift;
    my $query = "SELECT allele_alias_id 
                   FROM phenome.allele_alias
                  WHERE alias ILIKE ? and allele_id = ? and obsolete='f'";
    my $sth = $dbh->prepare($query);
    $sth->execute($alias, $allele_id);
    if (my ($id)=$sth->fetchrow_array()) { 
	return $id;
    }
    else { 
	return 0;
    }
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




=head2 get_allele_alias_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_allele_alias_id {
  my $self=shift;
  return $self->{allele_alias_id};

}

=head2 set_allele_alias_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_allele_alias_id {
  my $self=shift;
  $self->{allele_alias_id}=shift;
}

=head2 get_allele_alias

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_allele_alias {
  my $self=shift;
  return $self->{allele_alias};

}

=head2 set_allele_alias

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_allele_alias {
  my $self=shift;
  $self->{allele_alias}=shift;
}





###
1;#do not remove
###



