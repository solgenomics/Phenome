package CXGN::Phenome::Schema::AlleleDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("allele_dbxref");
__PACKAGE__->add_columns(
  "allele_dbxref_id",
  {
    data_type => "integer",
    default_value => "nextval('allele_dbxref_allele_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "allele_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "dbxref_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
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
__PACKAGE__->set_primary_key("allele_dbxref_id");
__PACKAGE__->add_unique_constraint("allele_dbxref_pkey", ["allele_dbxref_id"]);
__PACKAGE__->add_unique_constraint("allele_dbxref_id_key", ["allele_id", "dbxref_id"]);
__PACKAGE__->belongs_to(
  "allele_id",
  "CXGN::Phenome::Schema::Allele",
  { allele_id => "allele_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:sO4Awpq0uLDhrTf+eTEEfQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
