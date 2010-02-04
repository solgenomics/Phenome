package CXGN::Phenome::Schema::TomatoIlBin;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tomato_il_bin");
__PACKAGE__->add_columns(
  "il_bin_id",
  {
    data_type => "integer",
    default_value => "nextval('tomato_il_bin_il_bin_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "chromosome",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "n_marker_n",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "n_marker_s",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "s_marker_n",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "s_marker_s",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->set_primary_key("il_bin_id");
__PACKAGE__->add_unique_constraint("tomato_il_bin_pkey", ["il_bin_id"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:qfWTWJP7BNUyE5bi4uXz/w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
