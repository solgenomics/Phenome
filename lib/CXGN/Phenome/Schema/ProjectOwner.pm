use utf8;
package CXGN::Phenome::Schema::ProjectOwner;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::ProjectOwner

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<project_owner>

=cut

__PACKAGE__->table("project_owner");

=head1 ACCESSORS

=head2 project_owner_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'phenome.project_owner_project_owner_id_seq'

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sp_person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 create_date

  data_type: 'timestamp'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "project_owner_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "phenome.project_owner_project_owner_id_seq",
  },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "create_date",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</project_owner_id>

=back

=cut

__PACKAGE__->set_primary_key("project_owner_id");


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2021-04-27 18:42:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7mebMQz/E5EJiRnDmMrk9g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
