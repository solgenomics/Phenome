package CXGN::Phenome::Schema::TomatoTerm;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tomato_term");
__PACKAGE__->add_columns(
  "tomato_term_id",
  {
    data_type => "integer",
    default_value => "nextval('tomato_term_tomato_term_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "tomato_term_name",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 255,
  },
  "tomato_term_type",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 55,
  },
  "tomato_term_acc",
  {
    data_type => "character varying",
    default_value => "''::character varying",
    is_nullable => 0,
    size => 255,
  },
  "is_obsolete",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
  "is_root",
  {
    data_type => "bigint",
    default_value => "(0)::bigint",
    is_nullable => 0,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("tomato_term_id");
__PACKAGE__->add_unique_constraint("tomato_term_acc_key", ["tomato_term_acc"]);
__PACKAGE__->add_unique_constraint("tomato_term_pkey", ["tomato_term_id"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2009-07-04 22:42:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:A/ONfyF9aSsIR6uS52MTCQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
