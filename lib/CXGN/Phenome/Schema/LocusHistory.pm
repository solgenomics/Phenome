package CXGN::Phenome::Schema::LocusHistory;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

CXGN::Phenome::Schema::LocusHistory

=cut

__PACKAGE__->table("locus_history");

=head1 ACCESSORS

=head2 locus_history_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'locus_history_locus_history_id_seq'

=head2 locus_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 locus_name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 locus_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 original_symbol

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 gene_activity

  data_type: 'text'
  is_nullable: 1

=head2 locus_description

  data_type: 'text'
  is_nullable: 1

=head2 locus_notes

  data_type: 'text'
  is_nullable: 1

=head2 linkage_group

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 lg_arm

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 sp_person_id

  data_type: 'integer'
  is_nullable: 1

=head2 updated_by

  data_type: 'integer'
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

=head2 locus

  data_type: 'varchar'
  default_value: NULL::character varying
  is_nullable: 1
  size: 24

=cut

__PACKAGE__->add_columns(
  "locus_history_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "locus_history_locus_history_id_seq",
  },
  "locus_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "locus_name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "locus_symbol",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "original_symbol",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "gene_activity",
  { data_type => "text", is_nullable => 1 },
  "locus_description",
  { data_type => "text", is_nullable => 1 },
  "locus_notes",
  { data_type => "text", is_nullable => 1 },
  "linkage_group",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "lg_arm",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "sp_person_id",
  { data_type => "integer", is_nullable => 1 },
  "updated_by",
  { data_type => "integer", is_nullable => 1 },
  "obsolete",
  { data_type => "boolean", default_value => \"false", is_nullable => 1 },
  "create_date",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
  "locus",
  {
    data_type => "varchar",
    default_value => \"NULL::character varying",
    is_nullable => 1,
    size => 24,
  },
);
__PACKAGE__->set_primary_key("locus_history_id");

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


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-11-08 07:30:44
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TAv7QYfAUd2M1hdp/hUqQg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
