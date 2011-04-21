package CXGN::Phenome::Schema::AlleleDbxref;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::AlleleDbxref

=cut

__PACKAGE__->table("allele_dbxref");

=head1 ACCESSORS

=head2 allele_dbxref_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'allele_dbxref_allele_dbxref_id_seq'

=head2 allele_id

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
  "allele_dbxref_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "allele_dbxref_allele_dbxref_id_seq",
  },
  "allele_id",
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
__PACKAGE__->set_primary_key("allele_dbxref_id");
__PACKAGE__->add_unique_constraint("allele_dbxref_id_key", ["allele_id", "dbxref_id"]);

=head1 RELATIONS

=head2 allele_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Allele>

=cut

__PACKAGE__->belongs_to(
  "allele_id",
  "CXGN::Phenome::Schema::Allele",
  { allele_id => "allele_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3Z6yPRNAeObPz6AK7LiE5g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
