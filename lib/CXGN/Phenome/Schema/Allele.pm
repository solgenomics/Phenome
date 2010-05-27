package CXGN::Phenome::Schema::Allele;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("allele");
__PACKAGE__->add_columns(
  "allele_id",
  {
    data_type => "integer",
    default_value => "nextval('allele_allele_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "allele_symbol",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "allele_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "mode_of_inheritance",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 18,
  },
  "allele_synonym",
  {
    data_type => "character varying[]",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "allele_phenotype",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "allele_notes",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
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
  "updated_by",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "is_default",
  {
    data_type => "boolean",
    default_value => "true",
    is_nullable => 1,
    size => 1,
  },
  "sequence",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("allele_id");
__PACKAGE__->add_unique_constraint("allele_pkey", ["allele_id"]);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);
__PACKAGE__->has_many(
  "allele_alias",
  "CXGN::Phenome::Schema::AlleleAlias",
  { "foreign.allele_id" => "self.allele_id" },
);
__PACKAGE__->has_many(
  "allele_dbxrefs",
  "CXGN::Phenome::Schema::AlleleDbxref",
  { "foreign.allele_id" => "self.allele_id" },
);
__PACKAGE__->has_many(
  "allele_histories",
  "CXGN::Phenome::Schema::AlleleHistory",
  { "foreign.allele_id" => "self.allele_id" },
);
__PACKAGE__->has_many(
  "individual_alleles",
  "CXGN::Phenome::Schema::IndividualAllele",
  { "foreign.allele_id" => "self.allele_id" },
);
__PACKAGE__->has_many(
  "phenotypes",
  "CXGN::Phenome::Schema::Phenotype",
  { "foreign.allele_id" => "self.allele_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XWd4IDkUkX0WRxAFeJjUeg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
