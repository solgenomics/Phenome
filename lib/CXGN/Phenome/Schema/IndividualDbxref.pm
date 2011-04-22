package CXGN::Phenome::Schema::IndividualDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::IndividualDbxref

=cut

__PACKAGE__->table("individual_dbxref");

=head1 ACCESSORS

=head2 individual_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'individual_dbxref_individual_dbxref_id_seq'

=head2 individual_id

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
  "individual_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "individual_dbxref_individual_dbxref_id_seq",
  },
  "individual_id",
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
__PACKAGE__->set_primary_key("individual_dbxref_id");

=head1 RELATIONS

=head2 individual_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Individual>

=cut

__PACKAGE__->belongs_to(
  "individual_id",
  "CXGN::Phenome::Schema::Individual",
  { individual_id => "individual_id" },
);

=head2 individual_dbxref_evidences

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualDbxrefEvidence>

=cut

__PACKAGE__->has_many(
  "individual_dbxref_evidences",
  "CXGN::Phenome::Schema::IndividualDbxrefEvidence",
  { "foreign.individual_dbxref_id" => "self.individual_dbxref_id" },
  {},
);

=head2 individual_dbxref_evidence_histories

Type: has_many

Related object: L<CXGN::Phenome::Schema::IndividualDbxrefEvidenceHistory>

=cut

__PACKAGE__->has_many(
  "individual_dbxref_evidence_histories",
  "CXGN::Phenome::Schema::IndividualDbxrefEvidenceHistory",
  { "foreign.individual_dbxref_id" => "self.individual_dbxref_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qrRHA0SagUX67lpF6L9gGw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
