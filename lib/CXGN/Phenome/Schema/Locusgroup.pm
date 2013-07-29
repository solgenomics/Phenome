use utf8;
package CXGN::Phenome::Schema::Locusgroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::Locusgroup

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<locusgroup>

=cut

__PACKAGE__->table("locusgroup");

=head1 ACCESSORS

=head2 locusgroup_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'locusgroup_locusgroup_id_seq'

=head2 locusgroup_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 relationship_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "locusgroup_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "locusgroup_locusgroup_id_seq",
  },
  "locusgroup_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "relationship_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</locusgroup_id>

=back

=cut

__PACKAGE__->set_primary_key("locusgroup_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<locusgroup_locusgroup_name_key>

=over 4

=item * L</locusgroup_name>

=back

=cut

__PACKAGE__->add_unique_constraint("locusgroup_locusgroup_name_key", ["locusgroup_name"]);

=head1 RELATIONS

=head2 locusgroup_members

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusgroupMember>

=cut

__PACKAGE__->has_many(
  "locusgroup_members",
  "CXGN::Phenome::Schema::LocusgroupMember",
  { "foreign.locusgroup_id" => "self.locusgroup_id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CKP+PEIZEQLfOT4nfhof7A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
