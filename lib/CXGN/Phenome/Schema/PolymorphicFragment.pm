package CXGN::Phenome::Schema::PolymorphicFragment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("polymorphic_fragment");
__PACKAGE__->add_columns(
  "polymorphic_fragment_id",
  {
    data_type => "integer",
    default_value => "nextval('polymorphic_fragment_polymorphic_fragment_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "genotype_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "flanking_marker1_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "flanking_marker2_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "zygocity",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 15,
  },
  "linkage_group",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sp_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("polymorphic_fragment_id");
__PACKAGE__->add_unique_constraint("polymorphic_fragment_pkey", ["polymorphic_fragment_id"]);
__PACKAGE__->belongs_to(
  "genotype_id",
  "CXGN::Phenome::Schema::Genotype",
  { genotype_id => "genotype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:n/HnF3hcsz4Jj2YlfmsY2g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
