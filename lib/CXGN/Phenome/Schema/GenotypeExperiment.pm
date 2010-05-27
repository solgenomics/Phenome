package CXGN::Phenome::Schema::GenotypeExperiment;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("genotype_experiment");
__PACKAGE__->add_columns(
  "genotype_experiment_id",
  {
    data_type => "integer",
    default_value => "nextval('genotype_experiment_genotype_experiment_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
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
);
__PACKAGE__->set_primary_key("genotype_experiment_id");
__PACKAGE__->add_unique_constraint("genotype_experiment_pkey", ["genotype_experiment_id"]);
__PACKAGE__->has_many(
  "genotypes",
  "CXGN::Phenome::Schema::Genotype",
  {
    "foreign.genotype_experiment_id" => "self.genotype_experiment_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fZUOD3kpQdgZTjSR62gv2w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
