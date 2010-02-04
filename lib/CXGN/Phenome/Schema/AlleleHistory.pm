package CXGN::Phenome::Schema::AlleleHistory;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("allele_history");
__PACKAGE__->add_columns(
  "allele_history_id",
  {
    data_type => "integer",
    default_value => "nextval('allele_history_allele_history_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "allele_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
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
    size => 32,
  },
  "mode_of_inheritance",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 18,
  },
  "allele_phenotype",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "updated_by",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "sequence",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("allele_history_id");
__PACKAGE__->add_unique_constraint("allele_history_pkey", ["allele_history_id"]);
__PACKAGE__->belongs_to(
  "allele_id",
  "CXGN::Phenome::Schema::Allele",
  { allele_id => "allele_id" },
);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L0EQcC3vX55zYLXQhnFbtg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
