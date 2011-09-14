package CXGN::Phenome::Schema::Locusgroup;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::Locusgroup

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
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
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
  { data_type => "integer", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
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
__PACKAGE__->set_primary_key("locusgroup_id");
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
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:kqbVpVKixDszQ+mSViYt6A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
