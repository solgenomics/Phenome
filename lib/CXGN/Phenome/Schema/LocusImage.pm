package CXGN::Phenome::Schema::LocusImage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("locus_image");
__PACKAGE__->add_columns(
  "locus_image_id",
  {
    data_type => "integer",
    default_value => "nextval('phenome.locus_image_locus_image_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "image_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "locus_id",
  { data_type => "bigint", default_value => undef, is_nullable => 1, size => 8 },
  "obsolete",
  {
    data_type => "boolean",
    default_value => "false",
    is_nullable => 1,
    size => 1,
  },
  "sp_person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "create_date",
  {
    data_type => "timestamp with time zone",
    default_value => "now()",
    is_nullable => 1,
    size => 8,
  },
  "modified_date",
  {
    data_type => "timestamp with time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("locus_image_id");
__PACKAGE__->add_unique_constraint("locus_image_pkey", ["locus_image_id"]);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YSiv1ROABQC759t9K5/iKQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
