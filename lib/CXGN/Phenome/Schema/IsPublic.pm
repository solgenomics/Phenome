package CXGN::Phenome::Schema::IsPublic;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::IsPublic

=cut

__PACKAGE__->table("is_public");

=head1 ACCESSORS

=head2 is_public_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenome.is_public_is_public_id_seq'

=head2 population_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_public

  data_type: 'boolean'
  default_value: true
  is_nullable: 1

=head2 owner_id

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "is_public_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenome.is_public_is_public_id_seq",
  },
  "population_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_public",
  { data_type => "boolean", default_value => \"true", is_nullable => 1 },
  "owner_id",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("is_public_id");
__PACKAGE__->add_unique_constraint("is_public_population_id_key", ["population_id"]);

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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:krZfcAgJ6a9bORIe9gLkhQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
