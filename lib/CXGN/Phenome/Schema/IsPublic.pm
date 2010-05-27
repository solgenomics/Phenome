package CXGN::Phenome::Schema::IsPublic;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("is_public");
__PACKAGE__->add_columns(
  "is_public_id",
  {
    data_type => "integer",
    default_value => "nextval('phenome.is_public_is_public_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "population_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "is_public",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "owner_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("is_public_id");
__PACKAGE__->add_unique_constraint("is_public_pkey", ["is_public_id"]);
__PACKAGE__->add_unique_constraint("is_public_population_id_key", ["population_id"]);
__PACKAGE__->belongs_to(
  "population_id",
  "CXGN::Phenome::Schema::Population",
  { population_id => "population_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wQEKvQYGEaGkMcnN9dnrdg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
