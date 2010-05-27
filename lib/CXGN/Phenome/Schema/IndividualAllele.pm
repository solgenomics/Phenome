package CXGN::Phenome::Schema::IndividualAllele;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("individual_allele");
__PACKAGE__->add_columns(
  "individual_allele_id",
  {
    data_type => "integer",
    default_value => "nextval('individual_allele_individual_allele_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "individual_id",
  { data_type => "bigint", default_value => undef, is_nullable => 0, size => 8 },
  "allele_id",
  { data_type => "bigint", default_value => undef, is_nullable => 0, size => 8 },
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
);
__PACKAGE__->set_primary_key("individual_allele_id");
__PACKAGE__->add_unique_constraint("individual_allele_ukey", ["individual_id", "allele_id"]);
__PACKAGE__->add_unique_constraint("individual_allele_pkey", ["individual_allele_id"]);
__PACKAGE__->belongs_to(
  "individual_id",
  "CXGN::Phenome::Schema::Individual",
  { individual_id => "individual_id" },
);
__PACKAGE__->belongs_to(
  "allele_id",
  "CXGN::Phenome::Schema::Allele",
  { allele_id => "allele_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:++PxLKe9WMBBZWEYZXdYPw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
