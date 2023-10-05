use utf8;
package CXGN::Phenome::Schema::StockFile;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::StockFile

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_file>

=cut

__PACKAGE__->table("stock_file");

=head1 ACCESSORS

=head2 stock_file_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_file_stock_file_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 metadata_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1


=cut

__PACKAGE__->add_columns(
  "stock_file_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_file_stock_file_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "file_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "metadata_id",
  { data_type => "integer", default_value => 50, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_file_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_file_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2020-09-15 17:55:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8yv5QSlzaTYUSTdKrUWWkA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
