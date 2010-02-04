package CXGN::Phenome::Schema::Image;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("image");
__PACKAGE__->add_columns(
  "image_id",
  {
    data_type => "integer",
    default_value => "nextval('image_image_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "phenotype_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "image_file_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 20,
  },
);
__PACKAGE__->set_primary_key("image_id");
__PACKAGE__->add_unique_constraint("image_pkey", ["image_id"]);
__PACKAGE__->add_unique_constraint("image_file_name_key", ["image_file_name"]);
__PACKAGE__->belongs_to(
  "phenotype_id",
  "CXGN::Phenome::Schema::Phenotype",
  { phenotype_id => "phenotype_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Oyhtuzcedar7pJ2ujPAcUg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
