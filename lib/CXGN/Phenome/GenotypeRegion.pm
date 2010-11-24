
=head1 NAME

CXGN::Phenome::PolymorphicFragment - a class that defines the genetic composition of an individual

=head1 DESCRIPTION

DB tables: (phenome schema):

 genotype_region_id | integer                  | not null default nextval...
 genotype_id        | integer                  | 
 marker_id_nn       | bigint                   | 
 marker_id_ns       | bigint                   | not null
 marker_id_sn       | bigint                   | not null
 marker_id_ss       | bigint                   | 
 zygocity_code      | character varying(1)     | 
 lg_id              | integer                  | not null
 type               | character varying(32)    | not null
 name               | character varying(32)    | 
 sp_person_id       | integer                  | 
 modified_date      | timestamp with time zone | not null default now()
 create_date        | timestamp with time zone | not null default now()
 obsolete           | boolean                  | not null default false


=head1 AUTHOR(S)

Lukas Mueller (lam87@cornell.edu)

=head1 FUNCTIONS

This class implements the following functions:

=cut


use strict;


package CXGN::Phenome::GenotypeRegion;

#  A = 1 = Parent A, homozygous
#   H = 2 = Heterozygous
#   B = 3 = Parent B, homozygous
#   C = 4 = either 1 or 2 
#   D = 5 = either 3 or 2
our %mapmaker_codes = ( "1" => "A",
			 "2" => "H",
			 "3" => "B",
			 "4" => "C",
			 "5" => "D",
			 );
			 

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
	$self->set_genotype_region_id($id);
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
    my $query = "SELECT genotype_region_id, genotype_id, marker_id_nn, marker_id_ns, marker_id_sn, marker_id_ss, zygocity_code, lg_id, type, name
                   FROM phenome.genotype_region
                  WHERE genotype_region_id = ?
                        AND (obsolete='f' OR obsolete=NULL)";
    my $sth = $self->get_dbh()->prepare($query);
    $sth->execute($self->get_genotype_region_id());
    my ($genotype_region_id, $genotype_id, $marker_id_nn, $marker_id_ns, $marker_id_sn, $marker_id_ss, $zygocity_code, $lg_id, $type, $name, $sp_person_id, $modified_date, $create_date) =
	$sth->fetchrow_array();
    
    $self->set_genotype_region_id($genotype_region_id);
    $self->set_genotype_id($genotype_id);
    $self->set_marker_id_nn($marker_id_nn);
    $self->set_marker_id_ns($marker_id_ns);
    $self->set_marker_id_sn($marker_id_sn);
    $self->set_marker_id_ss($marker_id_ss);
    $self->set_zygocity_code($zygocity_code);
    $self->set_lg_id($lg_id);
    $self->set_type($type);
    $self->set_name($name);
    $self->set_sp_person_id($sp_person_id);
    $self->set_modification_date($modified_date);
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
    if ($self->get_genotype_region_id()) { 
	my $query = "UPDATE phenome.genome_region SET 
                       genotype_id = ?,
                       marker_id_nn = ?,
                       marker_id_ns = ?,
                       marker_id_sn = ?,
                       marker_id_ss = ?,
                       zygocity_code = ?,
                       lg_id = ?,
                       type = ?,
                       name = ?,
                       sp_person_id=?,
                       modified_date=now(),
                       obsolete=?,
                     WHERE genotype_region_id=?";
	my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_genotype_id(),
		      $self->get_marker_id_nn(),
		      $self->get_marker_id_ns(),
		      $self->get_marker_id_sn(),
		      $self->get_marker_id_ss(),
		      $self->get_zygocity_code(),
		      $self->get_genotype_region_id(),
		      $self->get_lg_id(),
		      $self->get_type(),
		      $self->get_name(),
		      $self->get_sp_person_id(),
		      $self->get_obsolete()
		      );
	return $self->get_genotype_region_id();
    }
    else { 
	my $query = "INSERT INTO phenome.genotype_region
                       (genotype_id, marker_id_nn, marker_id_ns, marker_id_sn, marker_id_ss, 
                        zygocity_code, lg_id, type, name, sp_person_id, modified_date, create_date, obsolete)
                     VALUES
                       (?, ?, ?, ?, ?, ?, ? ,?, ?, ? , now(), now(), 'f')
	               RETURNING genotype_region_id";
        my $sth = $self->get_dbh()->prepare($query);
	$sth->execute(
		      $self->get_genotype_id(),
		      $self->get_marker_id_nn(),
		      $self->get_marker_id_ns(),
		      $self->get_marker_id_sn(),
		      $self->get_marker_id_ss(),
		      $self->get_zygocity_code(),
		      $self->get_lg_id(),
		      $self->get_type(),
		      $self->get_name(),
		      $self->get_create_date()
		      );
	my ($id) = $sth->fetchrow_array;
	$self->set_genotype_region_id($id);
	return $id;
    }
}

# =head2 get_polymorphic_fragment_id

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub get_polymorphic_fragment_id {
#   my $self=shift;
#   return $self->{polymorphic_fragment_id};

# }

# =head2 set_polymorphic_fragment_id

#  Usage:
#  Desc:
#  Ret:
#  Args:
#  Side Effects:
#  Example:

# =cut

# sub set_polymorphic_fragment_id {
#   my $self=shift;
#   $self->{polymorphic_fragment_id}=shift;
# }

=head2 accessors set_genotype_region_id, get_genotype_region_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_genotype_region_id { 
    my $self=shift;
    return $self->{genotype_region_id};
}

sub set_genotype_region_id { 
    my $self=shift;
    $self->{genotype_region_id}=shift;
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



# =head2 accessors set_flanking_marker1_id, get_flanking_marker1_id

#   Property:	
#   Setter Args:	
#   Getter Args:	
#   Getter Ret:	
#   Side Effects:	
#   Description:	

# =cut

# sub get_flanking_marker1_id { 
#     my $self=shift;
#     return $self->{flanking_marker1_id};
# }

# sub set_flanking_marker1_id { 
#     my $self=shift;
#     $self->{flanking_marker1_id}=shift;
# }

# =head2 accessors set_flanking_marker2_id, get_flanking_marker2_id

#   Property:	
#   Setter Args:	
#   Getter Args:	
#   Getter Ret:	
#   Side Effects:	
#   Description:	

# =cut

# sub get_flanking_marker2_id { 
#     my $self=shift;
#     return $self->{flanking_marker2_id};
# }

# sub set_flanking_marker2_id { 
#     my $self=shift;
#     $self->{flanking_marker2_id}=shift;
# }

=head2 accessors set_marker_id_nn, get_marker_id_nn

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_marker_id_nn { 
my $self=shift;
return $self->{marker_id_nn};
}

sub set_marker_id_nn { 
my $self=shift;
$self->{marker_id_nn}=shift;
}



=head2 accessors set_marker_id_ns, get_marker_id_ns

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_marker_id_ns { 
my $self=shift;
return $self->{marker_id_ns};
}

sub set_marker_id_ns { 
my $self=shift;
$self->{marker_id_ns}=shift;
}


=head2 accessors set_marker_id_sn, get_marker_id_sn

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_marker_id_sn { 
my $self=shift;
return $self->{marker_id_sn};
}

sub set_marker_id_sn { 
my $self=shift;
$self->{marker_id_sn}=shift;
}

=head2 accessors set_marker_id_ss, get_marker_id_ss

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_marker_id_ss { 
my $self=shift;
return $self->{marker_id_ss};
}

sub set_marker_id_ss { 
my $self=shift;
$self->{marker_id_ss}=shift;
}




=head2 accessors set_zygocity_code, get_zygocity_code

  Property: 

  This property can have the values A, B, H, C, D, taken from the 
  definition in the mapmaker input file, with the following meanings:

  A = 1 = Parent A, homozygous
  H = 2 = Heterozygous
  B = 3 = Parent B, homozygous
  C = 4 = either 1 or 2 
  D = 5 = either 3 or 2

  (note that 4 or 5 are due to marker systems that are semi dominant)

  Side Effects:	The section will be rendered differently (colorwise) in the 
                overview diagram

=cut

sub get_zygocity_code { 
    my $self=shift;
    return $self->{zygocity_code};
}

sub set_zygocity_code { 
    my $self=shift;
    my $zygocity = shift;
    if ($zygocity !~  /A|B|C|D|H/i) { 
	die "Sorry zygocity code of '$zygocity' is not recognized in GenotypeRegion object.\n";
    }
    $self->{zygocity_code}=lc($zygocity);
}


=head2 accessors get_mapmaker_zygocity_code, set_mapmaker_zygocity_code

 Usage:        $gr->set_mapmaker_zygocity_code("3")
 Desc:         accepts the mapmaker style numeric zygocity codes and
               converts them to the alphabetic code used in the database.
 Property      see zygocity_code accessors.
 Side Effects:
 Example:

=cut

sub get_mapmaker_zygocity_code {
  my $self = shift;
  
  return $mapmaker_codes{$self->get_zygocity_code()};
}

sub set_mapmaker_zygocity_code {
  my $self = shift;
  my $code = shift;
  $self->set_zygocity_code( $mapmaker_codes{$code} );
}


=head2 accessors set_lg_id, get_lg_id

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_lg_id { 
my $self=shift;
return $self->{lg_id};
}

sub set_lg_id { 
my $self=shift;
$self->{lg_id}=shift;
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

=head2 accessors set_name, get_name

  Property:	
  Setter Args:	
  Getter Args:	
  Getter Ret:	
  Side Effects:	
  Description:	

=cut

sub get_name { 
    my $self=shift;
    return $self->{name};
}

sub set_name { 
    my $self=shift;
    $self->{name}=shift;
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

	my $sgn_base = $self->get_dbh()->base_schema("sgn");
    $self->get_dbh()->do("CREATE TABLE phenome.genotype_region ( 
                            genotype_region_id serial primary key,
                            genotype_id bigint references phenome.genotype,
                            marker_id_nn bigint references $sgn_base.marker,
                            marker_id_ns bigint references $sgn_base.marker,
                            marker_id_sn bigint references $sgn_base.marker,
                            marker_id_ss bigint references $sgn_base.marker,
                            zygocity_code varchar(15) CHECK (zygocity_code::text = 'a'::text OR zygocity_code::text = 'b'::text OR zygocity_code::text = 'c'::text OR zygocity_code::text = 'd'::text OR zygocity_code::text = 'h'::text),
                            lg_id bigint REFERENCE $sgn_base.linkage_group,
                            type text CHECK (\"type\"::text = 'bin'::text OR \"type\"::text = 'map'::text OR \"type\"::text = 'inbred'::text),
                            sp_person_id bigint references sgn_people.sp_person,
                            modified_date timestamp with time zone,
			    create_date timestamp with time zone,
			    obsolete boolean default false)");
    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.polymorphic_fragment TO web_usr");
    $self->get_dbh()->do("GRANT SELECT, UPDATE, INSERT ON phenome.polymorphic_fragment_polymorphic_fragment_id_seq TO web_usr");

    
}

return 1;
