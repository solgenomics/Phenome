package CXGN::Phenome::Schema::Phenotype;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("phenotype");
__PACKAGE__->add_columns(
  "phenotype_id",
  {
    data_type => "integer",
    default_value => "nextval('phenotype_phenotype_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "population_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "allele_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "allele_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "verified_allele",
  { data_type => "boolean", default_value => undef, is_nullable => 1, size => 1 },
  "phenotype_accession",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 20,
  },
  "phenotype_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 11,
  },
  "phenotype_details",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("phenotype_id");
__PACKAGE__->add_unique_constraint("phenotype_pkey", ["phenotype_id"]);
__PACKAGE__->add_unique_constraint("phenotype_accession_key", ["phenotype_accession"]);
__PACKAGE__->has_many(
  "images",
  "CXGN::Phenome::Schema::Image",
  { "foreign.phenotype_id" => "self.phenotype_id" },
);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);
__PACKAGE__->belongs_to(
  "population_id",
  "CXGN::Phenome::Schema::Population",
  { population_id => "population_id" },
);
__PACKAGE__->belongs_to(
  "allele_id",
  "CXGN::Phenome::Schema::Allele",
  { allele_id => "allele_id" },
);
__PACKAGE__->has_many(
  "phenotype_terms",
  "CXGN::Phenome::Schema::PhenotypeTerm",
  { "foreign.phenotype_id" => "self.phenotype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RS26191kAY/FGg7/4tJFGw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
