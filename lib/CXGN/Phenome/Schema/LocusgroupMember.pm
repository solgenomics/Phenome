package CXGN::Phenome::Schema::LocusgroupMember;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locusgroup_member");
__PACKAGE__->add_columns(
  "locusgroup_member_id",
  {
    data_type => "integer",
    default_value => "nextval('locusgroup_member_locusgroup_member_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locusgroup_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "direction",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "evidence_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "reference_id",
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
__PACKAGE__->set_primary_key("locusgroup_member_id");
__PACKAGE__->add_unique_constraint("locusgroup_member_pkey", ["locusgroup_member_id"]);
__PACKAGE__->add_unique_constraint("locusgroup_member_key", ["locus_id", "locusgroup_id"]);
__PACKAGE__->belongs_to(
  "locusgroup",
  "CXGN::Phenome::Schema::Locusgroup",
  { locusgroup_id => "locusgroup_id" },
);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vkfb/TVxZBr2HOJFHP9l4A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
