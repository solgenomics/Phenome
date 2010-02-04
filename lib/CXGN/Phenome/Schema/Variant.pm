package CXGN::Phenome::Schema::Variant;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("variant");
__PACKAGE__->add_columns(
  "variant_id",
  {
    data_type => "integer",
    default_value => "nextval('variant_variant_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "locus_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "variant_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "variant_gi",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "variant_notes",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("variant_id");
__PACKAGE__->add_unique_constraint("variant_gi_key", ["variant_gi"]);
__PACKAGE__->add_unique_constraint("variant_pkey", ["variant_id"]);
__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aFn9IttXuKBc4U+V3YUjzg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
