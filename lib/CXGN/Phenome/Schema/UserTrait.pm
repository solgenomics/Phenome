use utf8;
package CXGN::Phenome::Schema::UserTrait;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::UserTrait

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<user_trait>

=cut

__PACKAGE__->table("user_trait");

=head1 ACCESSORS

=head2 user_trait_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'user_trait_user_trait_id_seq'

=head2 cv_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=head2 definition

  data_type: 'text'
  is_nullable: 1

=head2 dbxref_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_trait_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_trait_user_trait_id_seq",
  },
  "cv_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "definition",
  { data_type => "text", is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_trait_id>

=back

=cut

__PACKAGE__->set_primary_key("user_trait_id");

=head1 RELATIONS

=head2 phenotype_user_traits

Type: has_many

Related object: L<CXGN::Phenome::Schema::PhenotypeUserTrait>

=cut

__PACKAGE__->has_many(
  "phenotype_user_traits",
  "CXGN::Phenome::Schema::PhenotypeUserTrait",
  { "foreign.user_trait_id" => "self.user_trait_id" },
  undef,
);

=head2 user_trait_units

Type: has_many

Related object: L<CXGN::Phenome::Schema::UserTraitUnit>

=cut

__PACKAGE__->has_many(
  "user_trait_units",
  "CXGN::Phenome::Schema::UserTraitUnit",
  { "foreign.user_trait_id" => "self.user_trait_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VeLu+hkbSO7NMfGu3QGqcQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
