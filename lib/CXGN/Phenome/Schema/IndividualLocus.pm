use utf8;
package CXGN::Phenome::Schema::IndividualLocus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::IndividualLocus

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<individual_locus>

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
  is_foreign_key: 1
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
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
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

=head1 PRIMARY KEY

=over 4

=item * L</individual_locus_id>

=back

=cut

__PACKAGE__->set_primary_key("individual_locus_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<individual_locus_ukey>

=over 4

=item * L</individual_id>

=item * L</locus_id>

=back

=cut

__PACKAGE__->add_unique_constraint("individual_locus_ukey", ["individual_id", "locus_id"]);

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

=head2 locus_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locus>

=cut

__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CEiTM4wzNQcGQRk5Wbm4ow


# You can replace this text with custom content, and it will be preserved on regeneration
1;
