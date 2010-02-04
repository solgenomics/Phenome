
=head1 NAME

CXGN::Phenome::PopulationDbxref 
display dbxrefs associated with a population

=head1 SYNOPSIS

=head1 AUTHOR

Isaak Y Tecle (iyt2@cornell.edu)

=cut
use CXGN::DB::Connection;
use CXGN::Phenome::Population; 

package CXGN::Phenome::PopulationDbxref;

use base qw / CXGN::Phenome::Main CXGN::Phenome::Population CXGN::DB::ModifiableI /;


=head2 new

 Usage: my $pop_dbxref = CXGN::Phenome::PopulationDbxref->new($dbh, $pop_dbxref_id);
 Desc:
 Ret:    
 Args: $dbh, $pop_dbxref_id
 Side Effects:
 Example:

=cut

sub new {
    my $class = shift;
    my $dbh= shift;
    my $id= shift; # the pop_dbxref_id of the PopulationDbxref object 
    
    my $args = {};  
 
    my $self=$class->SUPER::new($dbh);   

    $self->set_population_dbxref_id($id);
   
    if ($id) {
	$self->fetch($id);
    }
    
    return $self;
}




sub fetch {
    my $self=shift;

    my $pop_dbxref_query = $self->get_dbh()->prepare("SELECT population_id, dbxref_id, sp_person_id, create_date, modified_date, obsolete FROM phenome.population_dbxref WHERE population_dbxref_id=?");

    my $pop_dbxref_id=$self->get_population_dbxref_id();
         	   
    $pop_dbxref_query->execute($pop_dbxref_id);
    
    my ($pop_id, $dbxref_id, $sp_person_id, $create_date, $modified_date, $obsolete)=$pop_dbxref_query->fetchrow_array();
    $self->set_population_id($pop_id);
    $self->set_dbxref_id($dbxref_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_create_date($create_date);
    $self->set_modification_date($modified_date);
    $self->set_obsolete($obsolete);
}

=head2 get_population_dbxref_id

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
    my $pop_dbxref_id=$self->get_population_dbxref_id();
    print STDERR "obsolete= $obsolete, id= $pop_dbxref_id\n";
    if ($obsolete eq 'f') {
	my $query = "INSERT INTO phenome.population_dbxref (population_id, dbxref_id, sp_person_id) VALUES(?,?,?)";
	my $sth= $self->get_dbh()->prepare($query);
	
	$sth->execute($self->get_population_id, $self->get_dbxref_id, $self->get_sp_person_id);
		
    }else {
	my $query = "UPDATE phenome.population_dbxref SET obsolete='f', sp_person_id=? WHERE population_dbxref_id=?";
	my $sth= $self->get_dbh()->prepare($query);
	$sth->execute($self->get_sp_person_id, $pop_dbxref_id);
    }
    #return $pop_dbxref_id; 
}


=head2 delete

 Usage: $self->delete()
 Desc:  sets to obsolete an population_dbxref  
 Ret: nothing
 Args: none
 Side Effects:
 Example:

=cut

sub delete {

    my $self = shift;
    if ($self->get_population_dbxref_id()) { 
	my $query = "UPDATE phenome.population_dbxref SET obsolete='t', modified_date=now()
                  WHERE population_dbxref_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute($self->get_population_dbxref_id());
    }else { 
	print STDERR  "trying to delete an population_dbxref that has not yet been stored to db.\n";
    } 
   
}		     




=head2 get_population_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_population_dbxref_id {
  my $self=shift;
  return $self->{population_dbxref_id};

}

=head2 set_population_dbxref_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_population_dbxref_id {
  my $self=shift;
  $self->{population_dbxref_id}=shift;
}


=head2 get_population_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_population_id {
  my $self=shift;
  return $self->{population_id};

}

=head2 set_allele_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_population_id {
  my $self=shift;
  $self->{population_id}=shift;
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




# =head2 get_obsolete

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_obsolete {
#   my $self=shift;
#   return $self->{obsolete};

# }

# =head2 set_obsolete

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub set_obsolete {
#   my $self=shift;
#   $self->{obsolete}=shift;
# }



# =head2 get_allele_publications

#  Usage: my $population->get_allele_publications()
#  Desc:  get all the publications associated with a population
#  Ret:   an array of publication objects
#  Args:  none
#  Side Effects:
#  Example:

# =cut

# sub get_population_publications {
#    my $self=shift;
#    my $query = $self->get_dbh()->prepare("SELECT pub_id FROM pub_dbxref 
#                                           JOIN dbxref USING (dbxref_id)
#                                           JOIN phenome.population_dbxref USING (dbxref_id)
#                                           WHERE population_id = ?");
#    $query->execute($self->get_population_id());
#    my $publication;
#    my @publications;
#    while (my ($pub_id) = $query->fetchrow_array()) { 
# 	$publication = CXGN::Chado::Publication->new($self->get_dbh(), $pub_id);
# 	push @publications, $publication;
#    }
#    return @publications;

# }




###
1;#do not remove
###
