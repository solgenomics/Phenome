package CXGN::Phenome::Schema::LocusDbxrefEvidenceHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::LocusDbxrefEvidenceHistory

=cut

__PACKAGE__->table("locus_dbxref_evidence_history");

=head1 ACCESSORS

=head2 locus_dbxref_evidence_history_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'locus_dbxref_evidence_history_locus_dbxref_evidence_history_seq'

=head2 locus_dbxref_evidence_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 locus_dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 relationship_type

  data_type: 'integer'
  is_nullable: 1

=head2 evidence_code

  data_type: 'integer'
  is_nullable: 1

=head2 evidence_description

  data_type: 'integer'
  is_nullable: 1

=head2 evidence_with

  data_type: 'integer'
  is_nullable: 1

=head2 reference_id

  data_type: 'integer'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=head2 updated_by

  data_type: 'integer'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "locus_dbxref_evidence_history_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "locus_dbxref_evidence_history_locus_dbxref_evidence_history_seq",
  },
  "locus_dbxref_evidence_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "locus_dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "relationship_type",
  { data_type => "integer", is_nullable => 1 },
  "evidence_code",
  { data_type => "integer", is_nullable => 1 },
  "evidence_description",
  { data_type => "integer", is_nullable => 1 },
  "evidence_with",
  { data_type => "integer", is_nullable => 1 },
  "reference_id",
  { data_type => "integer", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
  "updated_by",
  { data_type => "integer", is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("locus_dbxref_evidence_history_id");

=head1 RELATIONS

=head2 locus_dbxref_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::LocusDbxref>

=cut

__PACKAGE__->belongs_to(
  "locus_dbxref_id",
  "CXGN::Phenome::Schema::LocusDbxref",
  { locus_dbxref_id => "locus_dbxref_id" },
);

=head2 locus_dbxref_evidence_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::LocusDbxrefEvidence>

=cut

__PACKAGE__->belongs_to(
  "locus_dbxref_evidence_id",
  "CXGN::Phenome::Schema::LocusDbxrefEvidence",
  { "locus_dbxref_evidence_id" => "locus_dbxref_evidence_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:U8EpotRGgNbhoVChDJNRWA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
