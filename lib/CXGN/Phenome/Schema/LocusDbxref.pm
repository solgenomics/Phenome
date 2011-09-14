package CXGN::Phenome::Schema::LocusDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::LocusDbxref

=cut

__PACKAGE__->table("locus_dbxref");

=head1 ACCESSORS

=head2 locus_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'locus_dbxref_locus_dbxref_id_seq'

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 dbxref_id

  data_type: 'integer'
  is_nullable: 0

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 sp_person_id

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

=cut

__PACKAGE__->add_columns(
  "locus_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "locus_dbxref_locus_dbxref_id_seq",
  },
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "dbxref_id",
  { data_type => "integer", is_nullable => 0 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "sp_person_id",
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
);
__PACKAGE__->set_primary_key("locus_dbxref_id");
__PACKAGE__->add_unique_constraint("locus_dbxref_id_key", ["locus_id", "dbxref_id"]);

=head1 RELATIONS

=head2 locus_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locus>

=cut

__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);

=head2 locus_dbxref_evidences

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusDbxrefEvidence>

=cut

__PACKAGE__->has_many(
  "locus_dbxref_evidences",
  "CXGN::Phenome::Schema::LocusDbxrefEvidence",
  { "foreign.locus_dbxref_id" => "self.locus_dbxref_id" },
  {},
);

=head2 locus_dbxref_evidence_histories

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusDbxrefEvidenceHistory>

=cut

__PACKAGE__->has_many(
  "locus_dbxref_evidence_histories",
  "CXGN::Phenome::Schema::LocusDbxrefEvidenceHistory",
  { "foreign.locus_dbxref_id" => "self.locus_dbxref_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z40tLsp6p/VdjHuVVQJ7AQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
