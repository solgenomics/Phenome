use utf8;
package CXGN::Phenome::Schema::DbxrefType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::DbxrefType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<dbxref_type>

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

=head1 PRIMARY KEY

=over 4

=item * L</dbxref_type_id>

=back

=cut

__PACKAGE__->set_primary_key("dbxref_type_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<dbxref_type_dbxref_type_definition_key>

=over 4

=item * L</dbxref_type_definition>

=back

=cut

__PACKAGE__->add_unique_constraint(
  "dbxref_type_dbxref_type_definition_key",
  ["dbxref_type_definition"],
);

=head2 C<dbxref_type_dbxref_type_name_key>

=over 4

=item * L</dbxref_type_name>

=back

=cut

__PACKAGE__->add_unique_constraint("dbxref_type_dbxref_type_name_key", ["dbxref_type_name"]);

=head2 C<dbxref_type_dbxref_type_url_key>

=over 4

=item * L</dbxref_type_url>

=back

=cut

__PACKAGE__->add_unique_constraint("dbxref_type_dbxref_type_url_key", ["dbxref_type_url"]);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ysrXRy/m/FbfaFrDE+Iiew


# You can replace this text with custom content, and it will be preserved on regeneration
1;
