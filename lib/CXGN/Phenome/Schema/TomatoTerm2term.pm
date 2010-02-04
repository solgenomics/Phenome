package CXGN::Phenome::Schema::TomatoTerm2term;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tomato_term2term");
__PACKAGE__->add_columns(
  "tomato_term2term_id",
  {
    data_type => "integer",
    default_value => "nextval('tomato_term2term_tomato_term2term_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "relationship_type_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "term1_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "term2_id",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "complete",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("tomato_term2term_id");
__PACKAGE__->add_unique_constraint(
  "term1_id_key",
  ["term1_id", "term2_id", "relationship_type_id"],
);
__PACKAGE__->add_unique_constraint("tomato_term2term_pkey", ["tomato_term2term_id"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:bbndc7wT4OcdcI+S/XbKUQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
