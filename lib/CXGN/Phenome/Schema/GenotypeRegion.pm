package CXGN::Phenome::Schema::GenotypeRegion;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::GenotypeRegion

=head1 DESCRIPTION

polymorphic regions from a genotype, delineated by markers in a certain linkage group on a certain map

=cut

__PACKAGE__->table("genotype_region");

=head1 ACCESSORS

=head2 genotype_region_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'genotype_region_genotype_region_id_seq'

=head2 genotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

optional genotype this region belongs to.  some regions are artificial, arising from combinations of other regions, and thus do not have an associated genotype

=head2 marker_id_nn

  data_type: 'bigint'
  is_nullable: 1

the north marker in the pair of markers bracketing the north end of this region. this may be null for regions at the north end of a linkage group

=head2 marker_id_ns

  data_type: 'bigint'
  is_nullable: 0

the south marker in the pair of markers bracketing the north end of this region

=head2 marker_id_sn

  data_type: 'bigint'
  is_nullable: 0

the north marker in the pair of markers bracketing the south end of this region

=head2 marker_id_ss

  data_type: 'bigint'
  is_nullable: 1

the south marker in the pair of markers bracketing the south end of this region. this may be null for regions at the south end of a linkage group.

=head2 zygocity_code

  data_type: 'varchar'
  is_nullable: 1
  size: 1

=head2 lg_id

  data_type: 'integer'
  is_nullable: 1

the linkage group in a specific version of a specific map where this region is located

=head2 type

  data_type: 'varchar'
  is_nullable: 0
  size: 32

the type of polymorphic region this is.  map is mapping experiment data, inbred is IL lines segments, and bin is a derived region based on a boolean combination of inbred fragments.  For bin regions, the specific boolean combination of fragments that make the bin is not stored.

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 32

special name for this region, if any.  optional

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

the person who loaded this datum.  optional

=head2 modified_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "genotype_region_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "genotype_region_genotype_region_id_seq",
  },
  "genotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "marker_id_nn",
  { data_type => "bigint", is_nullable => 1 },
  "marker_id_ns",
  { data_type => "bigint", is_nullable => 0 },
  "marker_id_sn",
  { data_type => "bigint", is_nullable => 0 },
  "marker_id_ss",
  { data_type => "bigint", is_nullable => 1 },
  "zygocity_code",
  { data_type => "varchar", is_nullable => 1, size => 1 },
  "lg_id",
  { data_type => "integer", is_nullable => 1 },
  "type",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
  "modified_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("genotype_region_id");

=head1 RELATIONS

=head2 genotype_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Genotype>

=cut

__PACKAGE__->belongs_to(
  "genotype_id",
  "CXGN::Phenome::Schema::Genotype",
  { genotype_id => "genotype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o4uIvRdXz+HauytrvryG+A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
