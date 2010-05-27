package CXGN::Phenome::Schema::IndividualDbxrefEvidence;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("individual_dbxref_evidence");
__PACKAGE__->add_columns(
  "individual_dbxref_evidence_id",
  {
    data_type => "integer",
    default_value => "nextval('individual_dbxref_evidence_individual_dbxref_evidence_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "individual_dbxref_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "relationship_type",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "evidence_code",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "evidence_description",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "evidence_with",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "reference_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "updated_by",
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
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
);
__PACKAGE__->set_primary_key("individual_dbxref_evidence_id");
__PACKAGE__->add_unique_constraint(
  "individual_dbxref_evidence_pkey",
  ["individual_dbxref_evidence_id"],
);
__PACKAGE__->belongs_to(
  "individual_dbxref_id",
  "CXGN::Phenome::Schema::IndividualDbxref",
  { individual_dbxref_id => "individual_dbxref_id" },
);
__PACKAGE__->has_many(
  "individual_dbxref_evidence_histories",
  "CXGN::Phenome::Schema::IndividualDbxrefEvidenceHistory",
  {
    "foreign.individual_dbxref_evidence_id" => "self.individual_dbxref_evidence_id",
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9dj69I9mfy00jjlYZrGC/Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
