package CXGN::Phenome::Schema::CrossType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("cross_type");
__PACKAGE__->add_columns(
  "cross_type_id",
  {
    data_type => "integer",
    default_value => "nextval('phenome.cross_type_cross_type_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "cross_type",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("cross_type_id");
__PACKAGE__->add_unique_constraint("cross_type_pkey", ["cross_type_id"]);
__PACKAGE__->has_many(
  "populations",
  "CXGN::Phenome::Schema::Population",
  { "foreign.cross_type_id" => "self.cross_type_id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:22VEH8VzpzbVdftrHV6tSQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
