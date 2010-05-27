package CXGN::Phenome::Schema::CvtermPubRanking;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cvterm_pub_ranking");
__PACKAGE__->add_columns(
  "cvterm_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "pub_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "rank",
  { data_type => "real", default_value => undef, is_nullable => 1, size => 4 },
  "match_type",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "headline",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Zv7rLJzsaEei7skIGbVaGA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
