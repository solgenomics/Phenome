package CXGN::Phenome::Schema::Locus;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus");
__PACKAGE__->add_columns(
  "locus_id",
  {
    data_type => "integer",
    default_value => "nextval('locus_locus_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locus_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 255,
  },
  "locus_symbol",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
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
  "locus_notes",
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
  "description",
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
  "common_name_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "updated_by",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("locus_id");
__PACKAGE__->add_unique_constraint("locus_pkey", ["locus_id"]);
__PACKAGE__->add_unique_constraint(
  "locus_symbol_key",
  ["locus_symbol", "common_name_id", "obsolete"],
);
__PACKAGE__->add_unique_constraint(
  "locus_name_key",
  ["locus_name", "common_name_id", "obsolete"],
);
__PACKAGE__->has_many(
  "alleles",
  "CXGN::Phenome::Schema::Allele",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "allele_histories",
  "CXGN::Phenome::Schema::AlleleHistory",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "loci",
  "CXGN::Phenome::Schema::IndividualLocus",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus2locus_subject_ids",
  "CXGN::Phenome::Schema::Locus2locus",
  { "foreign.subject_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus2locus_object_ids",
  "CXGN::Phenome::Schema::Locus2locus",
  { "foreign.object_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_alias",
  "CXGN::Phenome::Schema::LocusAlias",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_dbxrefs",
  "CXGN::Phenome::Schema::LocusDbxref",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locusgroup_members",
  "CXGN::Phenome::Schema::LocusgroupMember",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_histories",
  "CXGN::Phenome::Schema::LocusHistory",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_images",
  "CXGN::Phenome::Schema::LocusImage",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_markers",
  "CXGN::Phenome::Schema::LocusMarker",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_owners",
  "CXGN::Phenome::Schema::LocusOwner",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_pub_rankings",
  "CXGN::Phenome::Schema::LocusPubRanking",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_pub_ranking_validates",
  "CXGN::Phenome::Schema::LocusPubRankingValidate",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_registries",
  "CXGN::Phenome::Schema::LocusRegistry",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "locus_unigenes",
  "CXGN::Phenome::Schema::LocusUnigene",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "phenotypes",
  "CXGN::Phenome::Schema::Phenotype",
  { "foreign.locus_id" => "self.locus_id" },
);
__PACKAGE__->has_many(
  "variants",
  "CXGN::Phenome::Schema::Variant",
  { "foreign.locus_id" => "self.locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/kqBdt3R3TR1TF/CVMEFDQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
