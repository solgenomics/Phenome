package CXGN::Phenome::Schema::LocusDbxref;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus_dbxref");
__PACKAGE__->add_columns(
  "locus_dbxref_id",
  {
    data_type => "integer",
    default_value => "nextval('locus_dbxref_locus_dbxref_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locus_id",
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
__PACKAGE__->set_primary_key("locus_dbxref_id");
__PACKAGE__->add_unique_constraint("locus_dbxref_id_key", ["locus_id", "dbxref_id"]);
__PACKAGE__->add_unique_constraint("locus_dbxref_pkey", ["locus_dbxref_id"]);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);
__PACKAGE__->has_many(
  "locus_dbxref_evidences",
  "CXGN::Phenome::Schema::LocusDbxrefEvidence",
  { "foreign.locus_dbxref_id" => "self.locus_dbxref_id" },
);
__PACKAGE__->has_many(
  "locus_dbxref_evidence_histories",
  "CXGN::Phenome::Schema::LocusDbxrefEvidenceHistory",
  { "foreign.locus_dbxref_id" => "self.locus_dbxref_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mopmowfqlY2eEaVT1gLwWQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
