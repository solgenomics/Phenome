package CXGN::Phenome::Schema::AlleleAlias;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("allele_alias");
__PACKAGE__->add_columns(
  "allele_alias_id",
  {
    data_type => "integer",
    default_value => "nextval('allele_alias_allele_alias_id_seq'::regclass)",
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
  "allele_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "preferred",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
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
__PACKAGE__->set_primary_key("allele_alias_id");
__PACKAGE__->add_unique_constraint("allele_alias_pkey", ["allele_alias_id"]);
__PACKAGE__->belongs_to(
  "allele_id",
  "CXGN::Phenome::Schema::Allele",
  { allele_id => "allele_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KdotCQtvpglOKNarbDNaEg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
