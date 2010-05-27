package CXGN::Phenome::Schema::LocusAlias;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus_alias");
__PACKAGE__->add_columns(
  "locus_alias_id",
  {
    data_type => "integer",
    default_value => "nextval('locus_alias_locus_alias_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "alias",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "preferred",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "sp_person_id",
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
);
__PACKAGE__->set_primary_key("locus_alias_id");
__PACKAGE__->add_unique_constraint("locus_alias_pkey", ["locus_alias_id"]);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3HDK/DdC07xE0Hupj8Rsfg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
