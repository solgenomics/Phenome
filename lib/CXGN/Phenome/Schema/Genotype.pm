package CXGN::Phenome::Schema::Genotype;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("genotype");
__PACKAGE__->add_columns(
  "genotype_id",
  {
    data_type => "integer",
    default_value => "nextval('genotype_genotype_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "individual_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "experiment_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 100,
  },
  "reference_map_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "background_accession_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "preferred",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "sp_person_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
  "create_date",
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
  "genotype_experiment_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
);
__PACKAGE__->set_primary_key("genotype_id");
__PACKAGE__->add_unique_constraint("genotype_pkey", ["genotype_id"]);
__PACKAGE__->belongs_to(
  "genotype_experiment_id",
  "CXGN::Phenome::Schema::GenotypeExperiment",
  { "genotype_experiment_id" => "genotype_experiment_id" },
);
__PACKAGE__->belongs_to(
  "individual_id",
  "CXGN::Phenome::Schema::Individual",
  { individual_id => "individual_id" },
);
__PACKAGE__->has_many(
  "genotype_regions",
  "CXGN::Phenome::Schema::GenotypeRegion",
  { "foreign.genotype_id" => "self.genotype_id" },
);
__PACKAGE__->has_many(
  "polymorphic_fragments",
  "CXGN::Phenome::Schema::PolymorphicFragment",
  { "foreign.genotype_id" => "self.genotype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2SbkNTyTIgMvES8orC5TJg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
