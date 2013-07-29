use utf8;
package CXGN::Phenome::Schema::LocusOwner;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CXGN::Phenome::Schema::LocusOwner

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<locus_owner>

=cut

__PACKAGE__->table("locus_owner");

=head1 ACCESSORS

=head2 locus_owner_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'locus_owner_locus_owner_id_seq'

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sp_person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 granted_by

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "locus_owner_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "locus_owner_locus_owner_id_seq",
  },
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sp_person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "granted_by",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</locus_owner_id>

=back

=cut

__PACKAGE__->set_primary_key("locus_owner_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<locus_owner_key>

=over 4

=item * L</locus_id>

=item * L</sp_person_id>

=back

=cut

__PACKAGE__->add_unique_constraint("locus_owner_key", ["locus_id", "sp_person_id"]);

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


# Created by DBIx::Class::Schema::Loader v0.07033 @ 2013-07-16 23:38:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gCFtNE2T1HmpzpP6JgWo7Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
