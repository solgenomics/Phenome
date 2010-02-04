
=head1 NAME

CAUTION! This class is deprecated and replaced by CXGN::Phenome::GenotypeRegion. Please don't use it! ARGHGHGHGH!

CXGN::Phenome::PolymorphicFragment - a class that defines the genetic composition of an individual

=head1 DESCRIPTION

DB tables: (phenome schema):

genotype
genotype_id
experiment_name
reference_map_id 
###fragment_accession_id
background_accession_id
preferred boolean
sp_person_id
last_modified_date
creation_date
obsolete


polymorphic_fragment_id bigint serial primary key
genotype_id
flanking_marker1_id references sgn.marker.marker_id
flanking_marker2_id references sgn.marker.marker_id
zygocity [ heterozygous | homozygous | unknown ]
chromosome
type [ inbred, mutation ]

=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut

package CXGN::Phenome::PolymorphicFragment;

use base qw|  CXGN::Phenome::Main CXGN::DB::ModifiableI |;

=head2 function new

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub new {
    my $class = shift;
    my $dbh = shift;
    my $id = shift;
    my $self = $class->SUPER::new($dbh);
    if ($id) { 
	$self->set_polymorphic_fragment_id($id);
	$self->fetch();
    }
    return $self;
}

=head2 function fetch

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub fetch {
    my $self = shift;
    my $query = "SELECT polymorphic_fragment_id, genotype_id, flanking_marker1_id, flanking_marker2_id, zygosity, linkage_group, type
                   FROM phenome.polymorphic_fragment
                  WHERE polymorphic_fragment_id = ?";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_polymorphic_fragment_id());
    my ($polymorphic_fragment_id, $genotype_id, $flanking_marker1_id, $flanking_marker2_id, $zygosity, $linkage_group, $type) =
	$sth->fetchrow_array();
    
    $self->set_polymorphic_fragment_id($polymorphic_fragment_id);
    $self->set_genotype_id($genotype_id);
    $self->set_flanking_marker1_id($flanking_marker1_id);
    $self->set_flanking_marker2_id($flanking_marker2_id);
    $self->set_zygocity($zygocity);
    $self->set_linkage_group($linkage_group);
    $self->set_type($type);
    
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
    if ($self->get_polymorphic_fragment_id()) { 
	my $query = "UPDATE phenome.polymorphic_fragment SET 
                       genotype_id = ?,
                       flanking_marker1_id=?,
                       flanking_marker2_id=?,
                       zygocity = ?,
                       linkage_group = ?,
                       type = ?
                     WHERE polymorphic_fragment_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_genotype_id(),
		      $self->get_flanking_marker1_id(),
		      $self->get_flanking_marker2_id(),
		      $self->get_zygocity(),
		      $self->get_polymorphic_fragment_id(),
		      $self->get_linkage_group(),
		      $self->get_type()
		      );
	return $self->get_polymorphic_fragment_id();
    }
    else { 
	my $query = "INSERT INTO phenome.polymorphic_fragment 
                       (genotype_id, flanking_marker1_id, flanking_marker2_id, zygocity, linkage_group, type)
                     VALUES
                       (?, ?, ?, ?, ?, ?)";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_genotype_id(),
		      $self->get_flanking_marker1_id(),
		      $self->get_flanking_marker2_id(),
		      $self->get_zygocity(),
		      $self->get_linkage_group(),
		      $self->get_type()
		      );
	my $id = $self->get_dbh()->last_insert_id("polymorphic_fragment", "phenome");
	$self->set_polymorphic_fragment_id($id);
	return $id;
    }           
}

=head2 get_polymorphic_fragment_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_polymorphic_fragment_id {
  my $self=shift;
  return $self->{polymorphic_fragment_id};

}

=head2 set_polymorphic_fragment_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_polymorphic_fragment_id {
  my $self=shift;
  $self->{polymorphic_fragment_id}=shift;
}


=head2 get_genotype_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub get_genotype_id {
  my $self=shift;
  return $self->{genotype_id};

}

=head2 set_genotype_id

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub set_genotype_id {
  my $self=shift;
  $self->{genotype_id}=shift;
}



=head2 accessors set_flanking_marker1_id, get_flanking_marker1_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_flanking_marker1_id { 
    my $self=shift;
    return $self->{flanking_marker1_id};
}

sub set_flanking_marker1_id { 
    my $self=shift;
    $self->{flanking_marker1_id}=shift;
}

=head2 accessors set_flanking_marker2_id, get_flanking_marker2_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_flanking_marker2_id { 
    my $self=shift;
    return $self->{flanking_marker2_id};
}

sub set_flanking_marker2_id { 
    my $self=shift;
    $self->{flanking_marker2_id}=shift;
}

=head2 accessors set_zygocity, get_zygocity

  Property: 

  This property can have the values 1..5, taken from the 
  definition in the mapmaker input file, with the following meanings:

  1 = Parent A, homozygous
  2 = Heterozygous
  3 = Parent B, homozygous
  4 = either 1 or 2 
  5 = either 3 or 2

  (note that 4 or 5 are due to marker systems that are semi dominant)

  Side Effects:	The section will be rendered differently (colorwise) in the 
                overview diagram

=cut

sub get_zygocity { 
    my $self=shift;
    return $self->{zygocity};
}

sub set_zygocity { 
    my $self=shift;
    my $zygocity = shift;
    if ($zygocity =~ /^he/i) { 
	$zygocity = "heterozygous";
    }
    elsif ($zygocity =~ /ho/i) { 
	$zygocity = "homozygous";
    }
    else { 
	$zygocity = "unknown";
    }
    $self->{zygocity}=$zygocity;
}

=head2 accessors set_linkage_group, get_linkage_group

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_linkage_group { 
    my $self=shift;
    return $self->{linkage_group};
}

sub set_linkage_group { 
    my $self=shift;
    $self->{linkage_group}=shift;
}


=head2 accessors set_type, get_type

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_type { 
    my $self=shift;
    return $self->{type};
}

sub set_type { 
    my $self=shift;
    $self->{type}=shift;
}





=head2 function create_schema

  Synopsis:	
  Arguments:	
  Returns:	
  Side effects:	
  Description:	

=cut

sub create_schema { 
    my $self = shift;

	my $sgn_base = $self->get_dbh()->base_schema('sgn');
    $self->get_dbh()->do("CREATE TABLE phenome.polymorphic_fragment ( 
                            polymorphic_fragment_id serial primary key,
                            genotype_id bigint references phenome.genotype,
                            flanking_marker1_id bigint references $sgn_base.marker,
                            flanking_marker2_id bigint references $sgn_base.marker,
                            zygocity varchar(15),
                            mapmaker_code int,
                            linkage_group text,
                            type text,
                            sp_person_id bigint references sgn_people.sp_person,
                            modified_date timestamp with time zone,
			    create_date timestamp with time zone,
			    obsolete boolean default false)");
    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.polymorphic_fragment TO web_usr");
    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.polymorphic_fragment_polymorphic_fragment_id_seq TO web_usr");

    
}

return 1;
