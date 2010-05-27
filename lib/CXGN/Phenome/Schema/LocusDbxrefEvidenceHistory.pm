package CXGN::Phenome::Schema::LocusDbxrefEvidenceHistory;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus_dbxref_evidence_history");
__PACKAGE__->add_columns(
  "locus_dbxref_evidence_history_id",
  {
    data_type => "integer",
    default_value => "nextval('locus_dbxref_evidence_history_locus_dbxref_evidence_history_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locus_dbxref_evidence_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "locus_dbxref_id",
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
__PACKAGE__->set_primary_key("locus_dbxref_evidence_history_id");
__PACKAGE__->add_unique_constraint(
  "locus_dbxref_evidence_history_pkey",
  ["locus_dbxref_evidence_history_id"],
);
__PACKAGE__->belongs_to(
  "locus_dbxref_id",
  "CXGN::Phenome::Schema::LocusDbxref",
  { locus_dbxref_id => "locus_dbxref_id" },
);
__PACKAGE__->belongs_to(
  "locus_dbxref_evidence_id",
  "CXGN::Phenome::Schema::LocusDbxrefEvidence",
  { "locus_dbxref_evidence_id" => "locus_dbxref_evidence_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:q1zhoS/66/n7P0zrXNtc7A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
