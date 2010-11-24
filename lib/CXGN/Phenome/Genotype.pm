
=head1 NAME

=head1 DESCRIPTION

DB tables: (phenome schema):

genotype
genotype_id
experiment_name
reference_map_id 
fragment_accession_id
background_accession_id
preferred boolean
sp_person_id
modified_date
create_date
obsolete


inbred_fragment
genotype_id
inbred_fragment_id bigint serial primary key
fragment_top_marker_id references sgn.marker.marker_id
fragment_bottom_marker_id references sgn.marker.marker_id
zygocity [ heterozygous | homozygous | unknown ]
one_letter_code [ A | B | C | E | F | G | H ]

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=cut

use strict;

package CXGN::Phenome::Genotype;

use CXGN::Phenome::GenotypeRegion;

use base qw | CXGN::Phenome::Main  CXGN::DB::ModifiableI |;

=head2 function new

  Synopsis:	
  Arguments:	a database handle, an optional id
  Returns:	a Genotype object
  Side effects:	if an id is passed to the constructor, it will try to 
                fetch that id in the database and populate the object
                from the database. Otherwise, it creates an empty object.
                store() will create a new row in the database in that case.
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class -> SUPER::new($dbh);

    if ($id) { 
	$self->set_genotype_id($id);
	$self->fetch();
    }
    else { 
    }
    
    return $self;
}

# =head2 function fetch

#   Synopsis:	  function for internal use only.
#   Arguments:	
#   Returns:	
#   Side effects:	
#   Description:	

# =cut

sub fetch {
    my $self = shift;
    my $query = "SELECT genotype_id, individual_id,
                        sp_person_id,
                        genotype_experiment_id,
                        modified_date, create_date
                   FROM phenome.genotype
                  WHERE genotype_id=? AND (obsolete='f' OR obsolete IS NULL)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_genotype_id());
    my ($genotype_id, $individual_id, $sp_person_id, $genotype_experiment_id, $modified_date, $create_date) = $sth->fetchrow_array();
    $self->set_genotype_id($genotype_id);
    $self->set_individual_id($individual_id);
    $self->set_sp_person_id($sp_person_id);
    $self->set_genotype_experiment_id($genotype_experiment_id);
    $self->set_modified_date($modified_date);
    $self->set_create_date($create_date);
    
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
    if ($self->get_genotype_id()) { 
	my $query = "UPDATE phenome.genotype 
                         individual_id = ?,
                         sp_person_id =?,
                         genotype_experiment_id =?,
                         modified_date = now(),
                         create_date = ?,
                         obsolete = ?
                     WHERE 
                         genotype_id = ?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_individual_id(),
		      $self->get_sp_person_id(),
		      $self->get_genotype_experiment_id(),
		      $self->get_modified_date(),
		      $self->get_create_date(),
		      $self->get_obsolete()
		      );
	return $self->get_genotype_id();
    }
    else { 
	my $query = "INSERT INTO phenome.genotype  (
                                 individual_id,
                                 sp_person_id,
                                 genotype_experiment_id,
                                 modified_date,
                                 create_date,
                                 obsolete)
                          VALUES (?, ?, ?, now(), now(), 'f')
                          RETURNING genotype_id";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute( 
		       $self->get_individual_id(),
		       $self->get_sp_person_id(),
		       $self->get_genotype_experiment_id(),
		       );
	my ($id) = $sth->fetchrow_array();
	$self->set_genotype_id($id);
	return $id;
    }
}

=head2 accessors get_genotype_id, set_genotype_id

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub get_genotype_id { 
    my $self=shift;
    return $self->{genotype_id};
}

sub set_genotype_id { 
    my $self=shift;
    $self->{genotype_id}=shift;
}

=head2 accessors set_genotype_experiment_id, get_genotype_experiment_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_genotype_experiment_id { 
    my $self=shift;
    return $self->{genotype_experiment_id};
}

sub set_genotype_experiment_id { 
    my $self=shift;
    $self->{genotype_experiment_id}=shift;
}



# =head2 accessors get_reference_map_id, set_reference_map_id

#   Synopsis:	
#   Arguments:	
#   Returns:	
#   Side effects:	
#   Description:	

# =cut

# sub get_reference_map_id { 
#     my $self=shift;
#     return $self->{reference_map_id};
# }

# sub set_reference_map_id { 
#     my $self=shift;
#     $self->{reference_map_id}=shift;
# }


# =head2 accessors get_background_accession_id, set_background_accession_id

#   Synopsis:	
#   Property:     the background accession id, as defined by the 
#                 sgn.accession table, of the background parent of 
#                 this genotype.
#   Side effects:	
#   Description:	

# =cut

# sub get_background_accession_id { 
#     my $self=shift;
#     return $self->{background_accession_id};
# }

# =head2 function set_background_accession_id

#   Synopsis:	
#   Arguments:	
#   Returns:	
#   Side effects:	
#   Description:	

# =cut

# sub set_background_accession_id { 
#     my $self=shift;
#     $self->{background_accession_id}=shift;
# }

# =head2 get_experiment_name

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_experiment_name {
#   my $self=shift;
#   return $self->{experiment_name};

# }

# =head2 set_experiment_name

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub set_experiment_name {
#   my $self=shift;
#   $self->{experiment_name}=shift;
# }

# =head2 get_preferred

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_preferred {
#   my $self=shift;
#   return $self->{preferred};

# }

# =head2 set_preferred

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub set_preferred {
#   my $self=shift;
#   $self->{preferred}=shift;
# }

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
  Property:     The individual id of the individual this genotype
                information refers to.
  Side Effects:
  Example:

=cut

sub set_individual_id {
  my $self=shift;
  $self->{individual_id}=shift;
}


=head2 get_genotype_regions

 Usage: $self->get_genotype_regions
 Desc:   find the associated genotype regions
 Ret:    list of CXGN::Phenome::GenotypeRegion objects
 Args:   none
 Side Effects: none
 Example:

=cut

sub get_genotype_regions {
    my $self=shift;
    my @regions;
    if ($self->get_genotype_id) {
        my $q = "SELECT genotype_region_id FROM phenome.genotype_region WHERE genotype_id = ?";
        my $sth= $self->get_dbh->prepare($q);
        $sth->execute( $self->get_genotype_id);
        while ( my ($region_id) = $sth->fetchrow_array() ) {
            push @regions,  CXGN::Phenome::GenotypeRegion->new($self->get_dbh, $region_id);
        }
    }
    return @regions;
}



sub create_schema { 
    my $self = shift;
	my $sgn_base = $self->get_dbh()->base_schema('sgn');
    $self->get_dbh()->do("CREATE TABLE phenome.genotype (
                            genotype_id serial primary key,
                            individual_id bigint references phenome.individual,
                            experiment_name varchar(100),
                            reference_map_id bigint references $sgn_base.map,
                            background_accession_id bigint references $sgn_base.accession,
                            preferred boolean,
                            sp_person_id bigint references sgn_people.sp_person,
                            modified_date timestamp with time zone,
			    create_date timestamp with time zone,
			    obsolete boolean default false)");

    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.genotype TO web_usr");
    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.genotype_genotype_id_seq TO web_usr");

  

}

return 1;
