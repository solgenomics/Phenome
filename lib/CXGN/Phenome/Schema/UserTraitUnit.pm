use utf8;
package CXGN::Phenome::Schema::UserTraitUnit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::UserTraitUnit

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_trait_unit>

=cut

__PACKAGE__->table("user_trait_unit");

=head1 ACCESSORS

=head2 user_trait_unit_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_trait_unit_user_trait_unit_id_seq'

=head2 user_trait_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 unit_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 population_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_trait_unit_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_trait_unit_user_trait_unit_id_seq",
  },
  "user_trait_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "unit_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "population_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_trait_unit_id>

=back

=cut

__PACKAGE__->set_primary_key("user_trait_unit_id");

=head1 RELATIONS

=head2 population_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Population>

=cut

__PACKAGE__->belongs_to(
  "population_id",
  "CXGN::Phenome::Schema::Population",
  { population_id => "population_id" },
);

=head2 unit_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Unit>

=cut

__PACKAGE__->belongs_to(
  "unit_id",
  "CXGN::Phenome::Schema::Unit",
  { unit_id => "unit_id" },
);

=head2 user_trait_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::UserTrait>

=cut

__PACKAGE__->belongs_to(
  "user_trait_id",
  "CXGN::Phenome::Schema::UserTrait",
  { user_trait_id => "user_trait_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R4zj7jrQ5eHPnJhDTo9CoA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
