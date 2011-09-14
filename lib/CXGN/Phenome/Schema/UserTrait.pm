package CXGN::Phenome::Schema::UserTrait;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::UserTrait

=cut

__PACKAGE__->table("user_trait");

=head1 ACCESSORS

=head2 user_trait_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenome.user_trait_user_trait_id_seq'

=head2 cv_id

  data_type: 'integer'
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
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_trait_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenome.user_trait_user_trait_id_seq",
  },
  "cv_id",
  { data_type => "integer", is_nullable => 1 },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "definition",
  { data_type => "text", is_nullable => 1 },
  "dbxref_id",
  { data_type => "integer", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
);
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
  {},
);

=head2 user_trait_units

Type: has_many

Related object: L<CXGN::Phenome::Schema::UserTraitUnit>

=cut

__PACKAGE__->has_many(
  "user_trait_units",
  "CXGN::Phenome::Schema::UserTraitUnit",
  { "foreign.user_trait_id" => "self.user_trait_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Rq5PTWXSX2RlSeIkgASyYQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
