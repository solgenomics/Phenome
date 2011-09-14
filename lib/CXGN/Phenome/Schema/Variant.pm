package CXGN::Phenome::Schema::Variant;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::Variant

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
__PACKAGE__->set_primary_key("variant_id");
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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:50rEOF0yNrfZ0IXlShYWOg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
