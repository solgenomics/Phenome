use utf8;
package CXGN::Phenome::Schema::StockAllele;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::StockAllele

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<stock_allele>

=cut

__PACKAGE__->table("stock_allele");

=head1 ACCESSORS

=head2 stock_allele_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'stock_allele_stock_allele_id_seq'

=head2 stock_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 allele_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 metadata_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "stock_allele_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "stock_allele_stock_allele_id_seq",
  },
  "stock_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "allele_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "metadata_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</stock_allele_id>

=back

=cut

__PACKAGE__->set_primary_key("stock_allele_id");

=head1 RELATIONS

=head2 allele_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Allele>

=cut

__PACKAGE__->belongs_to(
  "allele_id",
  "CXGN::Phenome::Schema::Allele",
  { allele_id => "allele_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3Yt68yHReXPvljBJ96fCyQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
