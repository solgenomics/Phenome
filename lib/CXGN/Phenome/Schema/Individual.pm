package CXGN::Phenome::Schema::Individual;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("individual");
__PACKAGE__->add_columns(
  "individual_id",
  {
    data_type => "integer",
    default_value => "nextval('individual_individual_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "description",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sp_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
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
  "population_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "updated_by",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "common_name_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("individual_id");
__PACKAGE__->add_unique_constraint("individual_pkey", ["individual_id"]);
__PACKAGE__->has_many(
  "genotypes",
  "CXGN::Phenome::Schema::Genotype",
  { "foreign.individual_id" => "self.individual_id" },
);
__PACKAGE__->has_many(
  "germplasms",
  "CXGN::Phenome::Schema::Germplasm",
  { "foreign.individual_id" => "self.individual_id" },
);
__PACKAGE__->belongs_to(
  "population_id",
  "CXGN::Phenome::Schema::Population",
  { population_id => "population_id" },
);
__PACKAGE__->has_many(
  "individual_alleles",
  "CXGN::Phenome::Schema::IndividualAllele",
  { "foreign.individual_id" => "self.individual_id" },
);
__PACKAGE__->has_many(
  "individual_dbxrefs",
  "CXGN::Phenome::Schema::IndividualDbxref",
  { "foreign.individual_id" => "self.individual_id" },
);
__PACKAGE__->has_many(
  "individual_histories",
  "CXGN::Phenome::Schema::IndividualHistory",
  { "foreign.individual_id" => "self.individual_id" },
);
__PACKAGE__->has_many(
  "loci",
  "CXGN::Phenome::Schema::IndividualLocus",
  { "foreign.individual_id" => "self.individual_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JG1dUR52cTYOPwKRcYpIKQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
