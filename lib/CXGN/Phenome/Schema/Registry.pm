package CXGN::Phenome::Schema::Registry;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("registry");
__PACKAGE__->add_columns(
  "registry_id",
  {
    data_type => "integer",
    default_value => "nextval('registry_registry_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "symbol",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "origin",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "updated_by",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "status",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("registry_id");
__PACKAGE__->add_unique_constraint("symbol_name_key", ["symbol", "name"]);
__PACKAGE__->add_unique_constraint("registry_pkey", ["registry_id"]);
__PACKAGE__->has_many(
  "locus_registries",
  "CXGN::Phenome::Schema::LocusRegistry",
  { "foreign.registry_id" => "self.registry_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:agSIns5yOFIZmOmLdTuRBQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
