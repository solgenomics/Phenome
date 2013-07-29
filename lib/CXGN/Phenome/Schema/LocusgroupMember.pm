use utf8;
package CXGN::Phenome::Schema::LocusgroupMember;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::LocusgroupMember

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<locusgroup_member>

=cut

__PACKAGE__->table("locusgroup_member");

=head1 ACCESSORS

=head2 locusgroup_member_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'locusgroup_member_locusgroup_member_id_seq'

=head2 locusgroup_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 direction

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 evidence_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 reference_id

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
  "locusgroup_member_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "locusgroup_member_locusgroup_member_id_seq",
  },
  "locusgroup_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "direction",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "evidence_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "reference_id",
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

=item * L</locusgroup_member_id>

=back

=cut

__PACKAGE__->set_primary_key("locusgroup_member_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<locusgroup_member_key>

=over 4

=item * L</locus_id>

=item * L</locusgroup_id>

=back

=cut

__PACKAGE__->add_unique_constraint("locusgroup_member_key", ["locus_id", "locusgroup_id"]);

=head1 RELATIONS

=head2 locus_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locus>

=cut

__PACKAGE__->belongs_to(
  "locus_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "locus_id" },
);

=head2 locusgroup_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locusgroup>

=cut

__PACKAGE__->belongs_to(
  "locusgroup_id",
  "CXGN::Phenome::Schema::Locusgroup",
  { locusgroup_id => "locusgroup_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vlE6GQj/FKvr3grdJ9PN1g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
