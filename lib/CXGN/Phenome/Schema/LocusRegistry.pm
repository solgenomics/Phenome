package CXGN::Phenome::Schema::LocusRegistry;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus_registry");
__PACKAGE__->add_columns(
  "locus_registry_id",
  {
    data_type => "integer",
    default_value => "nextval('locus_registry_locus_registry_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "registry_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "modified_date",
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
__PACKAGE__->set_primary_key("locus_registry_id");
__PACKAGE__->add_unique_constraint("locus_registry_id_key", ["locus_id", "registry_id"]);
__PACKAGE__->add_unique_constraint("locus_registry_pkey", ["locus_registry_id"]);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);
__PACKAGE__->belongs_to(
  "registry_id",
  "CXGN::Phenome::Schema::Registry",
  { registry_id => "registry_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CZmFHlkFLhQO3dZ8f1XqTQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
