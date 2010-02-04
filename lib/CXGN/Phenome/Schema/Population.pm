package CXGN::Phenome::Schema::Population;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("population");
__PACKAGE__->add_columns(
  "population_id",
  {
    data_type => "integer",
    default_value => "nextval('population_population_id_seq'::regclass)",
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
  "person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
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
  "background_accession_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("population_id");
__PACKAGE__->add_unique_constraint("population_pkey", ["population_id"]);
__PACKAGE__->add_unique_constraint("population_name_key", ["name"]);
__PACKAGE__->has_many(
  "individuals",
  "CXGN::Phenome::Schema::Individual",
  { "foreign.population_id" => "self.population_id" },
);
__PACKAGE__->has_many(
  "phenotypes",
  "CXGN::Phenome::Schema::Phenotype",
  { "foreign.population_id" => "self.population_id" },
);
__PACKAGE__->has_many(
  "population_dbxrefs",
  "CXGN::Phenome::Schema::PopulationDbxref",
  { "foreign.population_id" => "self.population_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:43eeFEDrkehDKwE66+o26w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
