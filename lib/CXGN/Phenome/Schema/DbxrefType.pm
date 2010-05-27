package CXGN::Phenome::Schema::DbxrefType;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("dbxref_type");
__PACKAGE__->add_columns(
  "dbxref_type_id",
  {
    data_type => "integer",
    default_value => "nextval('dbxref_type_dbxref_type_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "dbxref_type_name",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 32,
  },
  "dbxref_type_definition",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
  "dbxref_type_url",
  {
    data_type => "character varying",
    default_value => undef,
    is_nullable => 1,
    size => 255,
  },
);
__PACKAGE__->set_primary_key("dbxref_type_id");
__PACKAGE__->add_unique_constraint("dbxref_type_pkey", ["dbxref_type_id"]);
__PACKAGE__->add_unique_constraint(
  "dbxref_type_dbxref_type_definition_key",
  ["dbxref_type_definition"],
);
__PACKAGE__->add_unique_constraint("dbxref_type_dbxref_type_url_key", ["dbxref_type_url"]);
__PACKAGE__->add_unique_constraint("dbxref_type_dbxref_type_name_key", ["dbxref_type_name"]);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2010-05-27 04:17:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8mB6OerJLjphHhmvmkrS8w


# You can replace this text with custom content, and it will be preserved on regeneration
1;
