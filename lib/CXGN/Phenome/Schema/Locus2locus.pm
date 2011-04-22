package CXGN::Phenome::Schema::Locus2locus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::Locus2locus

=cut

__PACKAGE__->table("locus2locus");

=head1 ACCESSORS

=head2 locus2locus_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'locus2locus_locus2locus_id_seq'

=head2 subject_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 object_id

  data_type: 'bigint'
  is_foreign_key: 1
  is_nullable: 1

=head2 relationship_id

  data_type: 'bigint'
  is_nullable: 1

=head2 evidence_id

  data_type: 'bigint'
  is_nullable: 1

=head2 reference_id

  data_type: 'bigint'
  is_nullable: 1

=head2 sp_person_id

  data_type: 'bigint'
  is_nullable: 1

=head2 obsolete

  data_type: 'boolean'
  default_value: false
  is_nullable: 1

=head2 modified_date

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 create_date

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 1
  original: {default_value => \"now()"}

=cut

__PACKAGE__->add_columns(
  "locus2locus_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "locus2locus_locus2locus_id_seq",
  },
  "subject_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "object_id",
  { data_type => "bigint", is_foreign_key => 1, is_nullable => 1 },
  "relationship_id",
  { data_type => "bigint", is_nullable => 1 },
  "evidence_id",
  { data_type => "bigint", is_nullable => 1 },
  "reference_id",
  { data_type => "bigint", is_nullable => 1 },
  "sp_person_id",
  { data_type => "bigint", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "modified_date",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);
__PACKAGE__->set_primary_key("locus2locus_id");

=head1 RELATIONS

=head2 subject_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locus>

=cut

__PACKAGE__->belongs_to(
  "subject_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "subject_id" },
);

=head2 object_id

Type: belongs_to

Related object: L<CXGN::Phenome::Schema::Locus>

=cut

__PACKAGE__->belongs_to(
  "object_id",
  "CXGN::Phenome::Schema::Locus",
  { locus_id => "object_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-04-21 15:09:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uv5hRzlCaYGmBxnOMGU3Ww


# You can replace this text with custom content, and it will be preserved on regeneration
1;
