use utf8;
package CXGN::Phenome::Schema::PhenotypeUserTrait;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::PhenotypeUserTrait

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<phenotype_user_trait>

=cut

__PACKAGE__->table("phenotype_user_trait");

=head1 ACCESSORS

=head2 phenotype_user_trait_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenotype_user_trait_phenotype_user_trait_id_seq'

=head2 user_trait_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 phenotype_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "phenotype_user_trait_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenotype_user_trait_phenotype_user_trait_id_seq",
  },
  "user_trait_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "phenotype_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</phenotype_user_trait_id>

=back

=cut

__PACKAGE__->set_primary_key("phenotype_user_trait_id");

=head1 RELATIONS

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:mMGCPnJ2/O26Icf5WoSE4A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
