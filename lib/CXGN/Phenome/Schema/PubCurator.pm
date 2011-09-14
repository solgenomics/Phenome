package CXGN::Phenome::Schema::PubCurator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::PubCurator

=cut

__PACKAGE__->table("pub_curator");

=head1 ACCESSORS

=head2 pub_curator_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pub_curator_pub_curator_id_seq'

=head2 pub_id

  data_type: 'integer'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=head2 status

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 date_stored

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 date_curated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 curated_by

  data_type: 'integer'
  is_nullable: 1

=head2 assigned_to

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "pub_curator_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pub_curator_pub_curator_id_seq",
  },
  "pub_id",
  { data_type => "integer", is_nullable => 1 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
  "status",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "date_stored",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "date_curated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "curated_by",
  { data_type => "integer", is_nullable => 1 },
  "assigned_to",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("pub_curator_id");
__PACKAGE__->add_unique_constraint("pub_curator_pub_id_key", ["pub_id"]);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-09-14 09:54:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MxscfIHir2s0ys2Qm1LoIg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
