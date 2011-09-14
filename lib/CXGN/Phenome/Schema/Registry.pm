package CXGN::Phenome::Schema::Registry;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::Registry

=cut

__PACKAGE__->table("registry");

=head1 ACCESSORS

=head2 registry_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'registry_registry_id_seq'

=head2 symbol

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 0

=head2 origin

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 0

=head2 updated_by

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

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "registry_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "registry_registry_id_seq",
  },
  "symbol",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "text", is_nullable => 0 },
  "origin",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 0 },
  "updated_by",
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
  "status",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("registry_id");
__PACKAGE__->add_unique_constraint("symbol_name_key", ["symbol", "name"]);

=head1 RELATIONS

=head2 locus_registries

Type: has_many

Related object: L<CXGN::Phenome::Schema::LocusRegistry>

=cut

__PACKAGE__->has_many(
  "locus_registries",
  "CXGN::Phenome::Schema::LocusRegistry",
  { "foreign.registry_id" => "self.registry_id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:WBPhqmCwu96j3Elfx1NHSw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
