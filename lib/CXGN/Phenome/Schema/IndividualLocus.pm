package CXGN::Phenome::Schema::IndividualLocus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::IndividualLocus

=cut

__PACKAGE__->table("individual_locus");

=head1 ACCESSORS

=head2 individual_locus_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'individual_locus_individual_locus_id_seq'

=head2 individual_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 locus_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 0

=head2 sp_person_id

  data_type: 'bigint'
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
  "individual_locus_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "individual_locus_individual_locus_id_seq",
  },
  "individual_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "locus_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 0 },
  "sp_person_id",
  { data_type => "bigint", is_nullable => 1 },
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
__PACKAGE__->set_primary_key("individual_locus_id");
__PACKAGE__->add_unique_constraint("individual_locus_ukey", ["individual_id", "locus_id"]);

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

=head2 individual_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Individual>

=cut

__PACKAGE__->belongs_to(
  "individual_id",
  "CXGN::Phenome::Schema::Individual",
  { individual_id => "individual_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A9Wamm6bqshj7wvxT5hi5g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
