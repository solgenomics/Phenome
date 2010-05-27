package CXGN::Phenome::Schema::IndividualAlias;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("individual_alias");
__PACKAGE__->add_columns(
  "individual_alias_id",
  {
    data_type => "integer",
    default_value => "nextval('individual_alias_individual_alias_id_seq'::regclass)",
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
  "individual_id",
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
__PACKAGE__->set_primary_key("individual_alias_id");
__PACKAGE__->add_unique_constraint("individual_alias_pkey", ["individual_alias_id"]);
__PACKAGE__->belongs_to(
  "individual_id",
  "CXGN::Phenome::Schema::Individual",
  { individual_id => "individual_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+pOF7BJBn9kyx7NSNomq2Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
