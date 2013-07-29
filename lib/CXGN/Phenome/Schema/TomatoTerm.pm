use utf8;
package CXGN::Phenome::Schema::TomatoTerm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::TomatoTerm

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<tomato_term>

=cut

__PACKAGE__->table("tomato_term");

=head1 ACCESSORS

=head2 tomato_term_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tomato_term_tomato_term_id_seq'

=head2 tomato_term_name

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 tomato_term_type

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 55

=head2 tomato_term_acc

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=head2 is_obsolete

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=head2 is_root

  data_type: 'bigint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "tomato_term_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tomato_term_tomato_term_id_seq",
  },
  "tomato_term_name",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "tomato_term_type",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 55 },
  "tomato_term_acc",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
  "is_obsolete",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
  "is_root",
  { data_type => "bigint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</tomato_term_id>

=back

=cut

__PACKAGE__->set_primary_key("tomato_term_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<tomato_term_acc_key>

=over 4

=item * L</tomato_term_acc>

=back

=cut

__PACKAGE__->add_unique_constraint("tomato_term_acc_key", ["tomato_term_acc"]);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dmM0X5+nY+JRdUGw7LAFsg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
