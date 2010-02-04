package CXGN::Phenome::Schema::LocusOwner;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus_owner");
__PACKAGE__->add_columns(
  "locus_owner_id",
  {
    data_type => "integer",
    default_value => "nextval('locus_owner_locus_owner_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "granted_by",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
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
__PACKAGE__->set_primary_key("locus_owner_id");
__PACKAGE__->add_unique_constraint("locus_owner_key", ["locus_id", "sp_person_id"]);
__PACKAGE__->add_unique_constraint("locus_owner_pkey", ["locus_owner_id"]);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7FO4YpZZy3I6asi6aBjk0Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
