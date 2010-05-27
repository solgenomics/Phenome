package CXGN::Phenome::Schema::LocusPubRankingValidate;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus_pub_ranking_validate");
__PACKAGE__->add_columns(
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "pub_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "validate",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 18,
  },
);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YEOXNS70s9I/dkPCDe3ptg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
