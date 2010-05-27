package CXGN::Phenome::Schema::LocusHistory;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus_history");
__PACKAGE__->add_columns(
  "locus_history_id",
  {
    data_type => "integer",
    default_value => "nextval('locus_history_locus_history_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "locus_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "locus_symbol",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "original_symbol",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "gene_activity",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "locus_description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "locus_notes",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "linkage_group",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "lg_arm",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 16,
  },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "updated_by",
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
);
__PACKAGE__->set_primary_key("locus_history_id");
__PACKAGE__->add_unique_constraint("locus_history_pkey", ["locus_history_id"]);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:DUKjYgsVeT8fzQmWRANicw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
