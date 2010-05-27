package CXGN::Phenome::Schema::GenotypeRegion;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("genotype_region");
__PACKAGE__->add_columns(
  "genotype_region_id",
  {
    data_type => "integer",
    default_value => "nextval('genotype_region_genotype_region_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "genotype_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "marker_id_nn",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "marker_id_ns",
  { data_type => "bigint", default_value => undef, is_nullable => 0, size => 8 },
  "marker_id_sn",
  { data_type => "bigint", default_value => undef, is_nullable => 0, size => 8 },
  "marker_id_ss",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "zygocity_code",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 1,
  },
  "lg_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 0,
    size => 8,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 0,
    size => 8,
  },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 0,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("genotype_region_id");
__PACKAGE__->add_unique_constraint("genotype_region_pkey", ["genotype_region_id"]);
__PACKAGE__->belongs_to(
  "genotype_id",
  "CXGN::Phenome::Schema::Genotype",
  { genotype_id => "genotype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KWV2iS4rXa/ydAHlOMNgDA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
