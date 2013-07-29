use utf8;
package CXGN::Phenome::Schema::CrossType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::CrossType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<cross_type>

=cut

__PACKAGE__->table("cross_type");

=head1 ACCESSORS

=head2 cross_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cross_type_cross_type_id_seq'

=head2 cross_type

  data_type: 'text'
  is_nullable: 0
  original: {data_type => "varchar"}

=cut

__PACKAGE__->add_columns(
  "cross_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cross_type_cross_type_id_seq",
  },
  "cross_type",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</cross_type_id>

=back

=cut

__PACKAGE__->set_primary_key("cross_type_id");

=head1 RELATIONS

=head2 populations

Type: has_many

Related object: L<CXGN::Phenome::Schema::Population>

=cut

__PACKAGE__->has_many(
  "populations",
  "CXGN::Phenome::Schema::Population",
  { "foreign.cross_type_id" => "self.cross_type_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:43
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3+wJLseaS/YhPXYZz1xCtg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
