use utf8;
package CXGN::Phenome::Schema::StockImage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::StockImage

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_image>

=cut

__PACKAGE__->table("stock_image");

=head1 ACCESSORS

=head2 stock_image_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_image_stock_image_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 image_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 metadata_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "stock_image_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_image_stock_image_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "image_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "metadata_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_image_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_image_id");


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4cyL17EWvt8Xg6/RSXN6Ew


# You can replace this text with custom content, and it will be preserved on regeneration
1;
