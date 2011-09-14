package CXGN::Phenome::Schema::Unit;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::Unit

=cut

__PACKAGE__->table("unit");

=head1 ACCESSORS

=head2 unit_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenome.unit_unit_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "unit_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenome.unit_unit_id_seq",
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("unit_id");

=head1 RELATIONS

=head2 user_trait_units

Type: has_many

Related object: L<CXGN::Phenome::Schema::UserTraitUnit>

=cut

__PACKAGE__->has_many(
  "user_trait_units",
  "CXGN::Phenome::Schema::UserTraitUnit",
  { "foreign.unit_id" => "self.unit_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:M9MdtI6I8mIeup8kBAkkiQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
