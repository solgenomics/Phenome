package CXGN::Phenome::Schema::Locusgroup;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locusgroup");
__PACKAGE__->add_columns(
  "locusgroup_id",
  {
    data_type => "integer",
    default_value => "nextval('locusgroup_locusgroup_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locusgroup_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "relationship_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("locusgroup_id");
__PACKAGE__->add_unique_constraint("locusgroup_locusgroup_name_key", ["locusgroup_name"]);
__PACKAGE__->add_unique_constraint("locusgroup_pkey", ["locusgroup_id"]);
__PACKAGE__->has_many(
  "locusgroup_members",
  "CXGN::Phenome::Schema::LocusgroupMember",
  { "foreign.locusgroup_id" => "self.locusgroup_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1VSSCOv85AMc+9T/cmI3LA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
