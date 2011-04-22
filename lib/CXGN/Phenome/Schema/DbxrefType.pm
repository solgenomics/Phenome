package CXGN::Phenome::Schema::DbxrefType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::DbxrefType

=cut

__PACKAGE__->table("dbxref_type");

=head1 ACCESSORS

=head2 dbxref_type_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'dbxref_type_dbxref_type_id_seq'

=head2 dbxref_type_name

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 dbxref_type_definition

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 dbxref_type_url

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "dbxref_type_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "dbxref_type_dbxref_type_id_seq",
  },
  "dbxref_type_name",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "dbxref_type_definition",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "dbxref_type_url",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("dbxref_type_id");
__PACKAGE__->add_unique_constraint(
  "dbxref_type_dbxref_type_definition_key",
  ["dbxref_type_definition"],
);
__PACKAGE__->add_unique_constraint("dbxref_type_dbxref_type_url_key", ["dbxref_type_url"]);
__PACKAGE__->add_unique_constraint("dbxref_type_dbxref_type_name_key", ["dbxref_type_name"]);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EcWBtsmpMKOF9sGuX/Vnfg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
