use utf8;
package CXGN::Phenome::Schema::Variant;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::Variant

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<variant>

=cut

__PACKAGE__->table("variant");

=head1 ACCESSORS

=head2 variant_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'variant_variant_id_seq'

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 variant_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 variant_gi

  data_type: 'integer'
  is_nullable: 1

=head2 variant_notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "variant_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "variant_variant_id_seq",
  },
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "variant_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "variant_gi",
  { data_type => "integer", is_nullable => 1 },
  "variant_notes",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</variant_id>

=back

=cut

__PACKAGE__->set_primary_key("variant_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<variant_gi_key>

=over 4

=item * L</variant_gi>

=back

=cut

__PACKAGE__->add_unique_constraint("variant_gi_key", ["variant_gi"]);

=head1 RELATIONS

=head2 locus_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locus>

=cut

__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UF2u5mutzN0FaRSjWZwD0A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
