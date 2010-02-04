package CXGN::Phenome::Schema::IndividualDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("individual_dbxref");
__PACKAGE__->add_columns(
  "individual_dbxref_id",
  {
    data_type => "integer",
    default_value => "nextval('individual_dbxref_individual_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "individual_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "dbxref_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
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
);
__PACKAGE__->set_primary_key("individual_dbxref_id");
__PACKAGE__->add_unique_constraint("individual_dbxref_pkey", ["individual_dbxref_id"]);
__PACKAGE__->belongs_to(
  "individual_id",
  "CXGN::Phenome::Schema::Individual",
  { individual_id => "individual_id" },
);
__PACKAGE__->has_many(
  "individual_dbxref_evidences",
  "CXGN::Phenome::Schema::IndividualDbxrefEvidence",
  { "foreign.individual_dbxref_id" => "self.individual_dbxref_id" },
);
__PACKAGE__->has_many(
  "individual_dbxref_evidence_histories",
  "CXGN::Phenome::Schema::IndividualDbxrefEvidenceHistory",
  { "foreign.individual_dbxref_id" => "self.individual_dbxref_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UN8pIZYYs/UFDpeVorKcYw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
