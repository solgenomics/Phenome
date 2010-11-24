
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

package CXGN::Phenome::GenotypeExperiment;

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
	$self->set_genotype_experiment_id($id);
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
    my $query = "SELECT genotype_experiment_id, experiment_name,  
                        reference_map_id,
                        background_accession_id,
                        preferred, sp_person_id,
                        modified_date, create_date
                   FROM phenome.genotype_experiment
                  WHERE genotype_experiment_id=? AND (obsolete='f' OR obsolete IS NULL)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_genotype_experiment_id());
    my ($genotype_experiment_id, $experiment_name, $reference_map_id, $background_accession_id, $preferred, $sp_person_id, $modified_date, $create_date) = $sth->fetchrow_array();
    $self->set_genotype_experiment_id($genotype_experiment_id);
    $self->set_experiment_name($experiment_name);
    $self->set_reference_map_id($reference_map_id);
    $self->set_background_accession_id($background_accession_id);
    $self->set_preferred($preferred);
    $self->set_sp_person_id($sp_person_id);
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
    if ($self->get_genotype_experiment_id()) { 
	my $query = "UPDATE phenome.genotype_experiment 
                         experiment_name = ?,
                         reference_map_id = ?,
                         background_accession_id =?,
                         preferred=?,
                         sp_person_id =?,
                         modified_date = now(),
                         create_date = ?,
                         obsolete = ?
                     WHERE 
                         genotype_experiment_id = ?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_experiment_name(),
		      $self->get_reference_map_id(),
		      $self->get_background_accession_id(),
		      $self->get_preferred(),
		      $self->get_sp_person_id(),
		      $self->get_modified_date(),
		      $self->get_create_date(),
		      $self->get_obsolete()
		      );
	return $self->get_genotype_id();
    }
    else { 
	my $query = "INSERT INTO phenome.genotype_experiment  (
                                 experiment_name,
                                 reference_map_id,
                                 background_accession_id,
                                 preferred,
                                 sp_person_id,
                                 modified_date,
                                 create_date,
                                 obsolete)
                          VALUES (?, ?, ?, ?, ?, now(), now(), ?)
                          RETURNING genotype_experiment_id";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		       $self->get_experiment_name(),
		       $self->get_reference_map_id(),
		       $self->get_background_accession_id(),
		       $self->get_preferred(),
		       $self->get_sp_person_id(),
		       $self->get_obsolete()
		       );
	my ($id) = $sth->fetchrow_array;
	$self->set_genotype_experiment_id($id);
	return $id;
    }
}

=head2 accessors get_genotype_experiment_id, set_genotype_experiment_id

  Synopsis:	
  Property:     the primary key of the genotype_experiment table.
  Side effects:	
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


=head2 get_reference_map_id, set_reference_map_id

  Synopsis:	
  Property:     an int specifying the map_id of the
                reference map (sgn.map).
  Side effects:	
  Description:	

=cut

sub get_reference_map_id { 
    my $self=shift;
    return $self->{reference_map_id};
}

sub set_reference_map_id { 
    my $self=shift;
    $self->{reference_map_id}=shift;
}


=head2 function get_background_accession_id, set_background_accession_id

  Synopsis:	
  Property:
  Side effects:	
  Description:	

=cut

sub get_background_accession_id { 
    my $self=shift;
    return $self->{background_accession_id};
}

sub set_background_accession_id { 
    my $self=shift;
    $self->{background_accession_id}=shift;
}

=head2 get_experiment_name, set_experiment_name

  Usage:
  Property: 
  Side Effects:
  Example:

=cut

sub get_experiment_name {
  my $self=shift;
  return $self->{experiment_name};

}

sub set_experiment_name {
  my $self=shift;
  $self->{experiment_name}=shift;
}

=head2 get_preferred, set_preferred

  Usage:
  Desc:
  Property:     Is this the preferred genotype experiment for the 
                given genotype? Should be used for display decisions.
  Side Effects:
  Example:

=cut

sub get_preferred {
  my $self=shift;
  return $self->{preferred};

}

sub set_preferred {
  my $self=shift;
  $self->{preferred}=shift;
}

=head2 function create_schema()

  Synopsis:	creates the schema for the table that this class
                works with
  Arguments:	none
  Returns:	nothing
  Side effects: 
  Description:	

=cut



sub create_schema { 
    my $self = shift;
	my $sgn_base = $self->get_dbh()->base_schema('sgn');
    $self->get_dbh()->do("CREATE TABLE phenome.genotype_experiment (
                            genotype_experiment_id serial primary key,         
                            experiment_name varchar(100),
                            reference_map_id bigint references $sgn_base.map,
                            background_accession_id bigint references $sgn_base.accession,
                            preferred boolean,
                            sp_person_id bigint REFERENCES sgn_people.sp_person,
                            modified_date timestamp with time zone,
			    create_date timestamp with time zone,
			    obsolete boolean default false)
        ");

    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.genotype_experiment TO web_usr");
    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.genotype_experiment_genotype_experiment_id_seq TO web_usr");


}

return 1;
