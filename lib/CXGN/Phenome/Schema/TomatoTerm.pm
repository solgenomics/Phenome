package CXGN::Phenome::Schema::TomatoTerm;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::TomatoTerm

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
  default_value: '0)::bigint'
  is_nullable: 0

=head2 is_root

  data_type: 'bigint'
  default_value: '0)::bigint'
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
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
  "is_root",
  { data_type => "bigint", default_value => "0)::bigint", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("tomato_term_id");
__PACKAGE__->add_unique_constraint("tomato_term_acc_key", ["tomato_term_acc"]);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:F2GsGG7ChKjiCZ9UNhZFsw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
