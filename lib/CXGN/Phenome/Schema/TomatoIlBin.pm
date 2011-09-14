package CXGN::Phenome::Schema::TomatoIlBin;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::TomatoIlBin

=cut

__PACKAGE__->table("tomato_il_bin");

=head1 ACCESSORS

=head2 il_bin_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tomato_il_bin_il_bin_id_seq'

=head2 chromosome

  data_type: 'integer'
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 n_marker_n

  data_type: 'integer'
  is_nullable: 1

=head2 n_marker_s

  data_type: 'integer'
  is_nullable: 1

=head2 s_marker_n

  data_type: 'integer'
  is_nullable: 1

=head2 s_marker_s

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "il_bin_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "tomato_il_bin_il_bin_id_seq",
  },
  "chromosome",
  { data_type => "integer", is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "n_marker_n",
  { data_type => "integer", is_nullable => 1 },
  "n_marker_s",
  { data_type => "integer", is_nullable => 1 },
  "s_marker_n",
  { data_type => "integer", is_nullable => 1 },
  "s_marker_s",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("il_bin_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b/xZLgdQmlNhNtiL/8sJog


# You can replace this text with custom content, and it will be preserved on regeneration
1;
